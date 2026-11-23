// RAMA: feature/Auth
// ============================================================================
// Interruptor del esquema de huella.
//   false -> biometría local (local_auth + secreto del dispositivo). Funciona
//            ya, sin configurar nada en el servidor.
//   true  -> passkeys (WebAuthn). Requiere assetlinks.json con el SHA-256 de
//            la app y el origin Android aceptado por el backend.
// Cuando el backend esté listo basta con cambiar este valor.
// ============================================================================

const bool kUsePasskeys = false;