# Breakout (Odin + raylib)

Prototipo de Breakout hecho en [Odin](https://odin-lang.org/) con `vendor:raylib`. Proyecto de aprendizaje: se construye de forma iterativa, sin buscar un producto final.

## Ejecutar

    odin run .

## Controles

- `A` / `D`: mover la paleta
- `Espacio`: lanzar la bola

## Features implementadas

- Ventana de 1280x720 a 60 FPS con delta time limitado
- Paleta controlable con límites en los bordes de la pantalla
- Grilla de bricks 8x16 (array fijo 2D) con separación y centrado, colores por fila
- Bricks con `hp` (hoy todos con 1 golpe)
- Bola con velocidad inicial y rebote en paredes laterales y techo (con reposición)
- Rebote con la paleta según el punto de impacto (ángulo máximo de 60°)
- Colisión con bricks (un brick por frame), resta de `hp` y puntaje
- Estados de juego: `Startup` (bola pegada a la paleta), `Playing`, `Game_Over`
- Vidas y reinicio de la bola al perderla
- Puntaje en pantalla

## Plan de features y mejoras

### Colisiones
- [ ] Detectar el lado del golpe (punto más cercano del rectángulo al centro de la bola)
- [ ] Rebote lateral en bricks (invertir `x` o `y` según el lado) y reposición correcta
- [ ] Definir el comportamiento al golpear los costados de la paleta
- [ ] Filtrar rebotes cuando la bola ya se aleja del objeto

### Flujo de juego
- [ ] Mostrar vidas en pantalla
- [ ] Pantalla de Game Over con reinicio
- [ ] Condición de victoria (contador de bricks restantes)
- [ ] Estado `Paused` (ya existe en el enum, falta implementarlo)
- [ ] Niveles (`level` existe en `Game` pero no se usa)

### Jugabilidad
- [ ] Reactivar la ganancia de velocidad (`BALL_SPEED_GAIN`) por hitos
- [ ] Bricks con más de 1 `hp` y color según vida restante
- [ ] Puntaje distinto por fila
- [ ] Power-ups (paleta más grande, multibola, etc.)

### Pulido
- [ ] Usar `brick.size` en vez de constantes al dibujar
- [ ] Sonidos y efectos
- [ ] Separar el código en varios archivos (colisiones, dibujo, estado)
