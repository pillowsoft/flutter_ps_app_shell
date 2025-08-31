// Minimal typed accessors for bindings & vars.
class Env {
  external String get SESSION_JWT_ISSUER;
  external String get SESSION_JWT_AUDIENCE;
  external String get R2_PUBLIC_BASE;
  external String get CF_ACCOUNT_ID;
  external dynamic get R2; // R2Bucket binding
  external dynamic get KV; // KVNamespace binding
  external dynamic get RATE_LIMITER; // Durable Object namespace
}
