# 4X Strategy

2D пошаговая 4X-стратегия на [Odin](https://odin-lang.org) с собственным движком поверх [raylib](https://www.raylib.com).
Карта на гексах. Разработка идёт маленькими шагами — по 0.001 версии, см. [CHANGELOG.md](CHANGELOG.md).

## Сборка (Windows)

Нужны [Odin](https://github.com/odin-lang/Odin/releases) и MSVC Build Tools.

```bat
build.bat        :: собрать в build\game.exe
build.bat run    :: собрать и запустить
build.bat test   :: прогнать тесты
```

По умолчанию компилятор ищется в `C:\odin\odin.exe`, другой путь можно задать через `set ODIN=...`.

## Управление

| Действие | Клавиши |
|---|---|
| Двигать карту | WASD / стрелки / перетаскивание правой или средней кнопкой мыши |
| Зум | Колёсико мыши |
| Выход | Esc |

## Лицензия

[GPL-3.0](LICENSE)
