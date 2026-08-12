/// <reference types="vite/client" />

interface ImportMetaEnv {
  /** Set to 'false' to call the real backend instead of the mock adapter. */
  readonly VITE_USE_MOCK_AUTH?: string;
  /** Override the API base URL (defaults to '/api/v1' via the dev proxy). */
  readonly VITE_API_BASE_URL?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
