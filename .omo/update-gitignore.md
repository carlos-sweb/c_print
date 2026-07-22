# Plan: Actualizar .gitignore para repositorio c_print

## Objetivo
Reemplazar el archivo `.gitignore` actual (que solo contiene "build") con una versión completa y organizada que ignore correctamente todos los artefactos de build, ejecutables, y archivos temporales del proyecto híbrido Zig/C.

## Contexto
El repositorio `c_print` es un proyecto híbrido que utiliza tanto Zig como C/CMake. El `.gitignore` actual es insuficiente y no ignora:
- Artefactos de Zig (`zig-out/`, `.zig-cache/`)
- Ejecutables de tests (`test_va`, `test_variadic`, etc.)
- Bibliotecas estáticas (`libmain.a`)
- Archivos de CMake generados
- Archivos objeto (`*.o`)

## Tareas

- [x] ### 1. Crear nuevo .gitignore
- **Archivo**: `/home/sweb/c_print/.gitignore`
- **Acción**: Reemplazar contenido completo
- **Contenido**: Ver sección "Nuevo contenido de .gitignore" abajo

- [x] ### 2. Limpiar archivos trackeados
Ejecutar los siguientes comandos para eliminar del índice de git los archivos que deberían ser ignorados:

```bash
# Eliminar directorios de build de Zig
git rm -r --cached zig-out/ .zig-cache/ 2>/dev/null || true

# Eliminar directorio de build de CMake
git rm -r --cached build/ 2>/dev/null || true

# Eliminar ejecutables y bibliotecas
git rm --cached main libmain.a 2>/dev/null || true
git rm --cached test_* 2>/dev/null || true
git rm --cached example_system_dashboard system_dashboard 2>/dev/null || true

# Eliminar archivos generados
git rm --cached c_print.pc 2>/dev/null || true
```

- [x] ### 3. Verificar cambios
```bash
# Ver estado de git
git status

# Verificar que los archivos correctos están marcados para eliminación
git diff --cached --name-only
```

- [x] ### 4. Commit de los cambios
```bash
git add .gitignore
git commit -m "chore: actualizar .gitignore con reglas completas para proyecto híbrido Zig/C

- Agregar artefactos de Zig (zig-out/, .zig-cache/)
- Agregar artefactos de CMake (build/, CMakeCache.txt, etc.)
- Agregar objetos compilados (*.o, *.a, *.so, etc.)
- Agregar ejecutables del proyecto (main, test_*, example_*)
- Agregar archivos generados (graphify-out/, *.pc)
- Agregar configuraciones de IDE (.vscode/, .idea/)
- Agregar archivos temporales y logs
- Agregar archivos específicos del SO (.DS_Store, Thumbs.db)
- Mantener archivos fuente en test/ y example_*.zig"
```

## Nuevo contenido de .gitignore

```gitignore
# ============================================
# Zig Build Artifacts
# ============================================
zig-cache/
.zig-cache/
zig-out/

# ============================================
# C/CMake Build Artifacts
# ============================================
build/
CMakeCache.txt
CMakeFiles/
cmake_install.cmake
Makefile
compile_commands.json
CMakeUserPresets.json

# ============================================
# Compiled Objects & Libraries
# ============================================
*.o
*.obj
*.a
*.lib
*.so
*.so.*
*.dylib
*.dll
*.exe

# ============================================
# Project Executables
# ============================================
main
test_*
!test/*.zig
!test/*.c
!test/*.h
example_*
!example_*.zig
system_dashboard

# ============================================
# Generated Files
# ============================================
graphify-out/
*.pc

# ============================================
# IDE & Editor Files
# ============================================
.vscode/
.idea/
*.sublime-project
*.sublime-workspace
*.swp
*.swo
*~
.DS_Store
Thumbs.db

# ============================================
# Logs & Temporary Files
# ============================================
*.log
*.tmp
*.bak
*.orig

# ============================================
# OS Generated Files
# ============================================
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db
```

## Notas importantes

1. **Excepciones críticas**: El `.gitignore` incluye excepciones para NO ignorar:
   - `!test/*.zig`, `!test/*.c`, `!test/*.h` - Archivos fuente en el directorio test/
   - `!example_*.zig` - Archivos fuente de ejemplos

2. **Seguridad**: Antes de ejecutar `git rm --cached`, verificar que los archivos a eliminar son realmente artefactos de build y no código fuente.

3. **Rollback**: Si algo sale mal, se puede restaurar el `.gitignore` original con:
   ```bash
   git checkout HEAD -- .gitignore
   ```

## Validación

Después de aplicar los cambios, verificar que:
- [x] `git status` muestra los archivos eliminados del índice
- [x] Los archivos fuente en `test/` y `example_*.zig` NO están marcados para eliminación
- [x] El commit se crea exitosamente
- [x] `git log --oneline -1` muestra el nuevo commit
