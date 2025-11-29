# 🎮 Columns – MIPS Assembly Game (CSC258 Final Project)

A complete, fully functional recreation of **Columns**, written entirely in **MIPS Assembly** for the CSC258 RISC architecture simulator.  
The game uses **bitmap display rendering**, **keyboard MMIO**, **custom glyph drawing**, and a full **game state machine** to deliver an arcade-style falling-block puzzle experience.

This project was developed as my final assignment for **CSC258 – Computer Organization**, focusing on low-level programming, memory mapping, and system design.

---

## ✨ Features

### 🎯 Complete Game Engine
- Full *Columns* gameplay with falling columns, rotation, left/right movement, and soft drop  
- 3 difficulty modes (Easy / Medium / Hard), each with unique gravity speeds  
- Dynamic gravity acceleration over time  
- Collision detection for walls, borders, stacked tiles, and bottom of grid  
- Landing logic that inserts tiles into the playfield grid  

### 💥 Matching & Cascade System
- Detects matches of **3 or more** in:
  - Horizontal  
  - Vertical  
  - Diagonal (both directions)  
- Marks all matched cells in a parallel buffer  
- Clears matches, applies gravity, updates score  
- Continues until no additional matches remain  
- Entire algorithm implemented manually in Assembly with explicit indexing

### 🖥️ Graphics & Rendering
- Low-level **memory-mapped bitmap drawing** at `0x10008000`  
- Custom 3×5 and 5×7 glyphs for:
  - Title screen  
  - Menu text  
  - Score display  
  - “GAME OVER” banner  
- Frame-by-frame rendering pipeline:
  - Clear screen  
  - Draw grid  
  - Draw falling column  
  - Draw scoreboard  

### 🎮 Interactive UI & Controls
**Menu:**
- `0` – Easy  
- `1` – Medium  
- `2` – Hard  
- `Q` – Quit

**Gameplay:**
- `A` – Move left  
- `D` – Move right  
- `W` – Rotate  
- `S` – Soft drop  
- `P` – Pause / Unpause  
- `R` – Reset  
- `B` – Back to menu  
- `Q` – Quit game  

### 🧾 Game States
- **Menu**  
- **Play**  
- **Pause**  
- **Game Over**

Each handled via a state dispatcher in Assembly.

---

## 🛠 Requirements

To run this project, open the file in **MARS** and enable:

### Bitmap Display:
- Unit Width: **8px**  
- Unit Height: **8px**  
- Display Width: **256px**  
- Display Height: **256px**  
- Base Address: `0x10008000`

### Keyboard MMIO:
- Status register: `0xffff0000`  
- ASCII register: `0xffff0004`

---

## ▶️ How to Run

1. Open **columns.asm** in SATURN  
2. Open **Bitmap Display** and **Keyboard MMIO Simulator**  
3. Configure settings as above  
4. Run the program  
5. Select difficulty from the menu and enjoy

---

## 📂 File Structure

```
columns.asm       # Full game implementation in MIPS Assembly
README.md         # Documentation
```

---

## 🧠 What I Learned

- Memory-mapped I/O (bitmap + keyboard)  
- Implementing games in a low-level environment  
- State machine architecture  
- Collision detection & grid indexing  
- Cascade algorithms without high-level data structures  
- Stack frames, register management, and calling conventions  
- Performance-conscious programming  

---

## 🚀 Future Enhancements
- Add sound effects  
- Add animations for tile clearing  
- Add next-piece preview  
- Save high scores to external file  
- Add different game modes  

---

## 📄 License

This project is open-source. Feel free to study or build on it.

