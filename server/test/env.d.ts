// Bindings seen by `env` from "cloudflare:workers" inside the tests.
declare namespace Cloudflare {
  interface Env {
    ROOM: DurableObjectNamespace<import("../src/room").Room>;
    LOBBY: DurableObjectNamespace<import("../src/lobby").Lobby>;
  }
}
