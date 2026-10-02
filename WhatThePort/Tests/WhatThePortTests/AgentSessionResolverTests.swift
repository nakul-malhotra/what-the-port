import Foundation
import Testing
@testable import WhatThePort

struct AgentSessionResolverTests {
    private let id = "c0a8012e-0000-4000-8000-000000000043"

    @Test func copilotMetadataIsOptionalAndBounded() throws {
        let home = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: home) }
        try FileManager.default.createDirectory(at: home, withIntermediateDirectories: true)
        let resolver = AgentSessionResolver(home: home)
        let environment = ["COPILOT_AGENT_SESSION_ID": id]

        let missing = try #require(resolver.resolve(environment: environment, cwd: "/shared/project"))
        #expect(missing.kind == .copilot)
        #expect(missing.id == id)
        #expect(missing.title == nil)
        #expect(missing.directory == nil)

        let workspace = home.appendingPathComponent(".copilot/session-state/\(id)/workspace.yaml")
        try FileManager.default.createDirectory(at: workspace.deletingLastPathComponent(), withIntermediateDirectories: true)
        try "cwd: /fixture/project\n".write(to: workspace, atomically: true, encoding: .utf8)
        #expect(resolver.resolve(environment: environment, cwd: "/shared/project")?.directory == "/fixture/project")

        try String(repeating: "x", count: 64 * 1024 + 1).write(to: workspace, atomically: true, encoding: .utf8)
        #expect(resolver.resolve(environment: environment, cwd: "/shared/project")?.directory == nil)
    }

    @Test func copilotDoesNotResolveFromMalformedIdentityOrCwd() {
        let resolver = AgentSessionResolver(home: FileManager.default.temporaryDirectory)
        #expect(resolver.resolve(environment: ["COPILOT_AGENT_SESSION_ID": "copilot-43"], cwd: "/shared/project") == nil)
        #expect(resolver.resolve(environment: [:], cwd: "/shared/project", codex: false) == nil)
    }
}
