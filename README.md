# BeStreak

App web minimalista (estilo BeReal, blanco/negro) para mantener rachas
diarias de foto en grupo, con cámara embebida y castigo pactado.

## Archivos

- `index.html` — las 3 pantallas (login, onboarding, feed, cámara)
- `main.js` — toda la lógica (auth, cámara, subida, rachas)
- `config.js` — tus credenciales de Supabase (edítalo)
- `schema.sql` — tablas + políticas RLS + storage

## Puesta en marcha (5 pasos)

1. **Crea un proyecto en [supabase.com](https://supabase.com)** (gratis).
2. **SQL Editor → pega y corre `schema.sql`** completo.
3. **Storage → New bucket** → nombre `daily-snaps` → marca **Public bucket**.
4. **Authentication → Providers → Email**: activa "Enable email provider"
   y "Enable Magic Link" (vienen activados por defecto). En
   **Authentication → URL Configuration** agrega la URL donde vas a
   desplegar (ej. `https://tu-app.vercel.app`) como Redirect URL.
5. **Project Settings → API**: copia `Project URL` y `anon public key`
   dentro de `config.js`.

## Probar localmente

Como usa cámara (`getUserMedia`), el navegador exige HTTPS o `localhost`.
Sirve la carpeta con cualquier servidor estático, por ejemplo:

```bash
npx serve .
```

## Desplegar gratis

- **Vercel**: `npx vercel` dentro de la carpeta (proyecto estático, sin build).
- **Netlify**: arrastra la carpeta en [app.netlify.com/drop](https://app.netlify.com/drop).

Después de desplegar, agrega la URL final como Redirect URL en Supabase
(paso 4) o el enlace mágico no te devolverá a la app.

## Cómo funciona

- **Login**: enlace mágico por correo (sin contraseña).
- **Onboarding**: al primer ingreso, eliges nombre de usuario y te unes
  a un grupo por código o creas uno nuevo (nombre + castigo).
- **Feed**: bloqueado y borroso hasta que subes tu foto del día; una
  vez subida, ves las fotos del grupo de hoy y la racha de cada quien.
- **Cámara**: se activa automáticamente al entrar a "Abrir cámara"
  (`getUserMedia`, cámara frontal), botón obturador captura el frame
  en un `<canvas>`, se comprime a WebP y se sube a Storage.
- **Rachas**: al subir una foto, si tu última foto anterior fue ayer,
  `streak_count` sube en 1; si hay un salto, se reinicia en 1 y el
  perfil queda marcado `status = 'failed'` una vez (ya lo verás
  reflejado en tu propio contador la próxima vez que abras la app).

## Limitación conocida (a propósito, para no sobre-construir)

No hay ningún proceso automático que revise a medianoche quién **no**
subió foto — el estado `failed` solo se calcula la próxima vez que esa
persona vuelve a postear. Si quieres detectarlo el mismo día en tiempo
real, el siguiente paso natural es una Supabase Edge Function con un
cron diario que recorra `profiles` y marque a quienes no tengan post
con la fecha de hoy. No lo agregué para mantener todo el flujo dentro
de Supabase Auth + Storage + Postgres sin infraestructura extra.
