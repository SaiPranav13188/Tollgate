import Foundation
import Testing
@testable import MCPShieldCore

/// One config that must fire each rule, and one that must not.
@Suite struct ConfigRulesTests {
    // CFG-001
    @Test func cfg001FiresOnPlainTextToken() {
        let f = ConfigRules.analyze(server("github", command: "docker", env: ["GITHUB_TOKEN": Fake.plainToken]))
        #expect(f.contains { $0.ruleID == "CFG-001" && $0.target == "github.env.GITHUB_TOKEN" })
    }
    @Test func cfg001SkipsPlaceholder() {
        #expect(!ruleIDs(server(command: "docker", env: ["GITHUB_TOKEN": "${GITHUB_TOKEN}"])).contains("CFG-001"))
    }

    // CFG-002
    @Test func cfg002FiresOnUnpinnedNpx() {
        #expect(ruleIDs(server(command: "npx", args: ["-y", "@modelcontextprotocol/server-memory"])).contains("CFG-002"))
        #expect(ruleIDs(server(command: "npx", args: ["-y", "some-server@latest"])).contains("CFG-002"))
    }
    @Test func cfg002SkipsPinnedNpx() {
        #expect(!ruleIDs(server(command: "npx", args: ["-y", "@modelcontextprotocol/server-memory@2025.4.25"])).contains("CFG-002"))
    }

    // CFG-003
    @Test func cfg003FiresOnRemoteHTTP() {
        #expect(ruleIDs(server(url: "http://mcp.example.com/sse")).contains("CFG-003"))
    }
    @Test func cfg003SkipsHTTPSAndLocalhost() {
        #expect(!ruleIDs(server(url: "https://mcp.example.com/sse")).contains("CFG-003"))
        #expect(!ruleIDs(server(url: "http://localhost:3000/mcp")).contains("CFG-003"))
        #expect(!ruleIDs(server(url: "http://127.0.0.1:3000/mcp")).contains("CFG-003"))
    }

    // CFG-004
    @Test func cfg004FiresOnShellDashC() {
        #expect(ruleIDs(server(command: "bash", args: ["-c", "cd ~/srv && node index.js"])).contains("CFG-004"))
        #expect(ruleIDs(server(command: "/bin/zsh", args: ["-lc", "server"])).contains("CFG-004"))
    }
    @Test func cfg004SkipsDirectLaunch() {
        #expect(!ruleIDs(server(command: "node", args: ["index.js", "-c", "conf.json"])).contains("CFG-004"))
        #expect(!ruleIDs(server(command: "bash", args: ["run.sh"])).contains("CFG-004"))
    }

    // CFG-005
    @Test func cfg005FiresOnHomeFolder() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        #expect(ruleIDs(server("filesystem", command: "npx", args: ["-y", "@modelcontextprotocol/server-filesystem@1.0.0", home])).contains("CFG-005"))
        #expect(ruleIDs(server("files", command: "npx", args: ["-y", "@modelcontextprotocol/server-filesystem@1.0.0", "/"])).contains("CFG-005"))
    }
    @Test func cfg005SkipsProjectFolderAndNonFilesystemServers() {
        #expect(!ruleIDs(server("filesystem", command: "npx", args: ["-y", "@modelcontextprotocol/server-filesystem@1.0.0", "/Users/me/projects/app"])).contains("CFG-005"))
        #expect(!ruleIDs(server("git", command: "uvx", args: ["mcp-server-git==0.6.2", "--repository", "~"])).contains("CFG-005"))
    }

    // CFG-006
    @Test func cfg006FiresOnWorldWritableExecutable() throws {
        let dir = try tempDir()
        let exe = dir.appending(path: "server")
        try Data("#!/bin/sh\n".utf8).write(to: exe)
        try FileManager.default.setAttributes([.posixPermissions: 0o777], ofItemAtPath: exe.path)
        #expect(ruleIDs(server(command: exe.path)).contains("CFG-006"))

        let script = dir.appending(path: "index.js")
        try Data("//".utf8).write(to: script)
        try FileManager.default.setAttributes([.posixPermissions: 0o666], ofItemAtPath: script.path)
        #expect(ruleIDs(server(command: "node", args: [script.path])).contains("CFG-006"))
    }
    @Test func cfg006SkipsOwnerOnlyPaths() throws {
        let dir = try tempDir()
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: dir.path)
        let exe = dir.appending(path: "server")
        try Data("#!/bin/sh\n".utf8).write(to: exe)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: exe.path)
        #expect(!ruleIDs(server(command: exe.path)).contains("CFG-006"))
        #expect(!ruleIDs(server(command: "/usr/bin/python3", args: ["-m", "srv"])).contains("CFG-006"))
    }

    @Test func cleanServerHasNoFindings() {
        let s = server("memory", command: "npx", args: ["-y", "@modelcontextprotocol/server-memory@2025.4.25"],
                       env: ["MEMORY_FILE_PATH": "/Users/me/memory.json"])
        #expect(Scanner.scan(s).findings.isEmpty)
        #expect(Scanner.scan(s).score == 100)
    }
}
