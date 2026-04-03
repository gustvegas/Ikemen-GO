# Auto-import de personajes

Deja aqui archivos `.zip` o `.rar` de personajes y IKEMEN-GO los agregara automaticamente al roster al iniciar.

Notas:
- No hace falta editar `select.def` para estos paquetes.
- Si el mismo archivo ya esta referenciado manualmente en `select.def`, no se duplica.
- El motor intentara encontrar el `.def` principal dentro del archivo usando:
  - `nombrezip.def`
  - `nombrezip/nombrezip.def`
  - un unico `.def` dentro del ZIP
  - un `.def` cuyo nombre coincida con el nombre del ZIP
