################# CSC258 Assembly Final Project ###################
# This file contains our implementation of Columns.
#
# Student 1: Lakshay Gupta, 1011404589
#
# We assert that the code submitted here is entirely our own 
# creation, and will indicate otherwise when it is not.
#
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       8
# - Unit height in pixels:      8
# - Display width in pixels:    256
# - Display height in pixels:   256
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

.data
##############################################################################
# Immutable Data
##############################################################################
HOWTOPLAY_MSG:
    .asciiz  "================ COLUMNS (CSC258) ================\n Controls During Menu:\n 0 = Easy Mode\n 1 = Medium Mode\n 2 = Hard Mode\n Q = Quit Game\n\n Controls During Gameplay:\n A = Move Left\n D = Move Right\n W = Rotate Column\n S = Soft Drop\n P = Pause / Unpause\n R = Reset (same difficulty)\n B = Back to Menu\n Q = Quit Game\n\n"

.align 2
ADDR_DSPL:  .word 0x10008000
ADDR_KBRD:  .word 0xffff0000

BITMAP_WIDTH:   .word 32
BITMAP_HEIGHT:  .word 32

# GRID CONSTANTS AND MEMORIY
GRID_COLS:  .word 9             # including borders 
GRID_ROWS:  .word 16            # 7x14 playfield without 

grid:           .space 144              # 9x16 cells = 144
marked_grid:    .space 144              # 9×16, same indexing as grid

# playfield constants 

# distance of top left border from 0x10008000
PLAYFIELD_X: .word 12
PLAYFIELD_Y: .word 8

# 4 directions: (dx, dy)  <- for matching algorithm 
dir_table:
    .word 1,0      # horizontal
    .word 0,1      # vertical
    .word 1,1      # diag down-right
    .word -1,1     # diag down-left

# colour table 
colour_table: 
    .word 0x000000      # 0 = empty/black
    .word 0x808080      # 1 = border (gray)
    .word 0xFF0000      # 2 = red
    .word 0xFF8000      # 3 = orange
    .word 0xFFFF00      # 4 = yellow
    .word 0x00FF00      # 5 = green
    .word 0x0000FF      # 6 = blue
    .word 0x8000FF      # 7 = purple

# difficulty  
DIFF_EASY:  .word 0 
DIFF_MED:   .word 1 
DIFF_HARD:  .word 2

# gravity
GRAV_EASY:      .word 50
GRAV_MED:       .word 35
GRAV_HARD:      .word 20

# Minimum gravity speeds (clamps)
GRAV_MIN_EASY:  .word 35
GRAV_MIN_MED:   .word 20
GRAV_MIN_HARD:  .word 7

# Gravity acceleration timing (7 seconds = ~420 frames)
GRAV_TICK_INTERVAL: .word 420

# Timer + next scheduled gravity acceleration
global_timer:        .word 0
next_gravity_tick:   .word 0

# score variables 
score:              .word 000
high_score:         .word 000

# ASCII constants
ASCII_0:    .word 0x30
ASCII_1:    .word 0x31
ASCII_2:    .word 0x32

ASCII_A:    .word 0x61
ASCII_B:    .word 0x62
ASCII_D:    .word 0x64
ASCII_P:    .word 0x70     
ASCII_Q:    .word 0x71
ASCII_R:    .word 0x72
ASCII_S:    .word 0x73
ASCII_W:    .word 0x77


# state constants 
STATE_MENU:   .word 0
STATE_PLAY:   .word 1
STATE_PAUSE:  .word 2
STATE_OVER:   .word 3



##############################################################################
# Mutable Data
##############################################################################
.align 2
FallingColumn:  
    .word 0                     # x (column of gems (in grid))
    .word 0                     # y (row of TOP gem (in grid))
    .word 0                     # gem0 index (top) 
    .word 0                     # gem1 index (middle) 
    .word 0                     # gem2 index (bottom) 
    # add more values for features if needed. 

GRAV_DELAY:     .word 5     # will be overwritten based on mode later
grav_counter:   .word 0

# menu, game states/flags 
game_difficulty:    .word 1         # default: MEDIUM
game_state:         .word 0         # 0=menu, 1=play, 2=pause, 3=game over
game_running:       .word 1         # 1 = running, 0 = exit
landing_flag:       .word 0         # 1 = landing triggered
game_over_flag:     .word 0         # 0 = normal, 1 = game over



##############################################################################
# 3×5 glyph bitmaps (each row is a 3-bit mask) for graphics
##############################################################################
glyph0: .word 7,5,5,5,7                 # 0: 111,101,101,101,111  
glyph1: .word 2,2,2,2,2                 # 1: 010,010,010,010,010
glyph2: .word 7,1,7,4,7                 # 2: 111,001,111,100,111
glyph3: .word 7,1,7,1,7                 # 3: 111,001,111,001,111
glyph4: .word 5,5,7,1,1                 # 4: 101,101,111,001,001
glyph5: .word 7,4,7,1,7                 # 5: 111,100,111,001,111        
glyph6: .word 7,4,7,5,7                 # 6: 111,100,111,101,111 
glyph7: .word 7,1,1,1,1                 # 7: 111,001,001,001,001
glyph8: .word 7,5,7,5,7                 # 8: 111,101,111,101,111 
glyph9: .word 7,5,7,1,7                 # 9: 111,101,111,001,111

glyph_A: .word 7,5,7,5,5                # A: 111,101,111,101,101
glyph_C: .word 7,4,4,4,7                # C: 111,100,100,100,111
glyph_D: .word 6,5,5,5,6                # D: 110,101,101,101,110
glyph_E: .word 7,4,6,4,7                # E: 111,100,110,100,111  
glyph_H: .word 5,5,7,5,5                # H: 101,101,111,101,101
glyph_I: .word 7,2,2,2,7                # I: 111,010,010,010,111
glyph_L: .word 4,4,4,4,7                # L: 100,100,100,100,111
glyph_M: .word 5,7,5,5,5                # M: 101,111,101,101,101
glyph_N: .word 5,7,7,5,5                # N: 101,111,111,101,101
glyph_O: .word 7,5,5,5,7                # O: 111,101,101,101,111
glyph_R: .word 6,5,6,5,5                # R: 110,101,110,101,101
glyph_S: .word 7,4,7,1,7                # S: 111,100,111,001,111
glyph_U: .word 5,5,5,5,7                # U: 101,101,101,101,111
glyph_V: .word 5,5,5,5,2                # V: 101,101,101,101,010
glyph_Y: .word 5,5,7,2,2                # Y: 101,101,111,010,010

glyph_COLON: .word 0,2,0,2,0

##############################################################################
# 5×7 GAME OVER GLYPHS
##############################################################################
.align 2
glyph5x7_G: .word 31,17,16,23,17,17,31
glyph5x7_A: .word 14,17,17,31,17,17,17
glyph5x7_M: .word 17,27,21,17,17,17,17
glyph5x7_E: .word 31,16,30,16,16,16,31
glyph5x7_O: .word 31,17,17,17,17,17,31
glyph5x7_V: .word 17,17,17,17,10,4,4
glyph5x7_R: .word 30,17,17,30,20,18,17



##############################################################################
# Code
##############################################################################
.text
.globl main


##############################################################################
# MAIN
##############################################################################
main:
    # print how-to-play text to console
    la $a0, HOWTOPLAY_MSG
    li $v0, 4
    syscall
    # start in menu mode
    sw $zero, game_state                        # 0 = menu
    j state_dispatch

# state_dispatch:
#   - Checks if we should exit
#   - Jumps to the handler for the current game_state
state_dispatch:
    lw $t9, game_running
    beq $t9, $zero, game_exit                   # quit program if game_running==0

    lw $t0, game_state

    li $t1, 0                                   # MENU
    beq $t0, $t1, menu_state

    li $t1, 1                                   # PLAY
    beq $t0, $t1, game_loop

    li $t1, 2                                   # PAUSE
    beq $t0, $t1, pause_state

    li $t1, 3                                   # GAME OVER
    beq $t0, $t1, game_over_state

    # fallback: go back to dispatcher
    j state_dispatch


game_loop: 
    # game_running is already checked in state_dispatch

    lw $t1, game_over_flag
    bnez $t1, go_call_handler                   # if game_over_flag = 1, initiate game_over

    # we're in PLAY state
    jal handle_input 
    jal update_gravity
    jal landing_sequence
    
    # GRAVITY ACCELERATION TIMER
    lw $t0, global_timer
    addi $t0, $t0, 1
    sw $t0, global_timer

    jal check_gravity_acceleration

    jal render_frame                            # redraw everything using recorded values in grid 
    
    # frame delay (apprx. 16ms) 
    li $v0, 32
    li $a0, 16
    syscall
    
    j state_dispatch
    
go_call_handler:
    jal game_over_handler
    j state_dispatch

##############################################################################
# INIT 
##############################################################################
init_game: 
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    jal init_grid_and_borders
    jal init_difficulty_settings
    jal init_column

    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

# init_grid_and_borders
# - Initializes ALL 9x16 cells
# - Border cells = 1 (TILE_BORDER)
# - Interior cells = 0 (TILE_EMPTY)
init_grid_and_borders:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    la $t0, grid                        # pointer to grid base
    lw $t2, GRID_ROWS                   # total rows (GRID_ROWS) 
    lw $t3, GRID_COLS                   # total columns (GRID_COLS)
    
    li $t1, 0                           # init row counter, r = 0 
    
row_loop:
    beq $t1, $t2, done                  # if r == 16 stop
    li $t4, 0                           # init column counter, c = 0

col_loop:
    beq $t4, $t3, next_row              # if c == 9 go next row

    # Compute index = r * 9 + c
    mul $t5, $t1, $t3                   # rows x columns 
    add $t5, $t5, $t4                   # add column -> index
    add $t6, $t0, $t5                   # cell address (since each cell = 1 byte, index = offset)

    # Determine if this is a border cell
    # Border if: r == 0 OR r == 15 OR c == 0 OR c == 8
    beq $t1, $zero, write_border        # top
    li $t8, 15
    beq $t1, $t8, write_border          # bottom
    beq $t4, $zero, write_border        # left
    li $t8, 8
    beq $t4, $t8, write_border          # right

    # interior -> TILE_EMPTY (0)
    sb $zero, 0($t6)
    j cell_done

write_border:
    li $t7, 1                           # TILE_BORDER
    sb $t7, 0($t6)

cell_done:
    addi $t4, $t4, 1                    # c++
    j col_loop

next_row:
    addi $t1, $t1, 1                    # r++
    j row_loop

done:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# init_column; initializes falling piece at top, sets its gem colors randomly
init_column:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    # check spawn collision BEFORE creating the new piece
    jal check_spawn_collision
    lw $t0, game_over_flag
    bnez $t0, ic_done                   # if blocked, skip spawning

    la $t0, FallingColumn

    li $t1, 4
    sw $t1, 0($t0)

    li $t2, 1
    sw $t2, 4($t0)

    jal rand_color_index
    sw $a0, 8($t0)

    jal rand_color_index
    sw $a0, 12($t0)

    jal rand_color_index
    sw $a0, 16($t0)

ic_done:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# check_spawn_collision
# Checks whether the 3 spawn cells needed for a new falling
# column are empty. If any is blocked, sets game_over_flag = 1.
check_spawn_collision:
    # x = 4
    li $t0, 4
    # top/middle/bottom rows
    li $t1, 1
    li $t2, 2
    li $t3, 3

    la $t4, grid
    lw $t5, GRID_COLS

    # check row 1 
    mul $t6, $t1, $t5
    add $t6, $t6, $t0
    add $t6, $t4, $t6
    lb $t7, 0($t6)
    bnez $t7, spawn_blocked

    # check row 2 
    mul $t6, $t2, $t5
    add $t6, $t6, $t0
    add $t6, $t4, $t6
    lb $t7, 0($t6)
    bnez $t7, spawn_blocked

    # check row 3
    mul $t6, $t3, $t5
    add $t6, $t6, $t0
    add $t6, $t4, $t6
    lb $t7, 0($t6)
    bnez $t7, spawn_blocked

    # all clear
    jr $ra

spawn_blocked:
    li $t8, 1
    sw $t8, game_over_flag
    jr $ra

# init_difficulty_settings
# Loads GRAV_DELAY based on difficulty
init_difficulty_settings:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    sw $zero, grav_counter              # ensure counter is 0 upon initialization
     
    lw $t0, game_difficulty             # 0,1,2

    la $t1, GRAV_EASY
    la $t2, GRAV_MED
    la $t3, GRAV_HARD

    beq $t0, $zero, set_easy            # difficulty == EASY ?

    li $t4, 1
    beq $t0, $t4, set_med               # difficulty == MED ?

    # otherwise HARD
set_hard:
    lw $t5, 0($t3)
    sw $t5, GRAV_DELAY
    j set_tick

set_easy:
    lw $t5, 0($t1)
    sw $t5, GRAV_DELAY
    j set_tick

set_med:
    lw $t5, 0($t2)
    sw $t5, GRAV_DELAY

set_tick:
    # next_gravity_tick = GRAV_TICK_INTERVAL
    la $t6, GRAV_TICK_INTERVAL
    lw $t7, 0($t6)
    sw $t7, next_gravity_tick

    # reset global timer
    sw $zero, global_timer

    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# reset_game
# Clears grid, resets gameplay flags, gravity counter,
# clears game_over_flag, and spawns a new column.
reset_game:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    jal update_high_score
    # Clear the grid + borders
    jal init_grid_and_borders

    # Reset all gameplay flags
    sw $zero, game_over_flag
    sw $zero, landing_flag
    sw $zero, score     

    # Reset grav counters 
    jal init_difficulty_settings
    
    # Spawn a new falling column
    jal init_column
    
    # If the spawn is blocked, init_column will set game_over_flag -> handled next frame
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

##############################################################################
# HANDLE INPUT (for PLAY state)
##############################################################################
# handle_input
# Checks keyboard MMIO, interprets keys:
#   A = move left
#   D = move right
#   W = rotate
#   S = soft drop
#   P = pause/unpause
#   R = reset (same difficulty)
#   Q = quit game
handle_input:
    addi $sp, $sp, -8
    sw $ra, 4($sp)

    # Load keyboard base address
    lw $t0, ADDR_KBRD

    # Check if a key is pressed (word 0)
    lw $t1, 0($t0)                      # first word: 1 = key pressed
    beq $t1, $zero, hi_done             # no key -> exit

    # Load actual key ASCII (word 4)
    lw $t2, 4($t0)
    
    # PAUSE (P)
    li $t3, 0x70                        # 'p'
    beq $t2, $t3, hi_pause
    
    # QUIT (Q)
    li $t3, 0x71                        # 'q'
    beq $t2, $t3, hi_quit
    
    # RESET (R)
    li $t3, 0x72                        # 'r'
    beq $t2, $t3, hi_reset
    
    # MOVE LEFT (A)
    li $t3, 0x61                        # 'a'
    beq $t2, $t3, hi_left
    
    # MOVE RIGHT (D)
    li $t3, 0x64                        # 'd'
    beq $t2, $t3, hi_right

    # ROTATE (W)
    li $t3, 0x77                        # 'w'
    beq $t2, $t3, hi_rotate

    # SOFT DROP (S)
    li $t3, 0x73                        # 's'
    beq $t2, $t3, hi_drop
    
    # BACK TO MENU (B)
    lw $t3, ASCII_B
    beq $t2, $t3, hi_back_to_menu

    j hi_done                           # key was pressed but not mapped

# key handlers
hi_back_to_menu:
    jal reset_game              # clear grid, gravity, flags
    sw $zero, game_state        # STATE_MENU = 0
    j hi_done

hi_rotate:
    la $t0, FallingColumn

    lw $t1, 8($t0)              # gem0
    lw $t2, 12($t0)             # gem1
    lw $t3, 16($t0)             # gem2
    
    # cycle: gem2 -> gem1, gem1 -> gem0, gem0 -> gem2
    sw $t3, 8($t0)              # new gem0 = old gem2
    sw $t1, 12($t0)             # new gem1 = old gem0
    sw $t2, 16($t0)             # new gem2 = old gem1

    j hi_done
    
hi_left:
    li $a0, -1              # dx = -1
    li $a1,  0              # dy = 0
    jal can_move
    beq $v0, $zero, hi_done

    # ok -> update x
    la $t0, FallingColumn
    lw $t1, 0($t0)
    addi $t1, $t1, -1
    sw  $t1, 0($t0)

    j hi_done

hi_right:
    li $a0, 1               # dx = +1
    li $a1, 0
    jal can_move
    beq $v0, $zero, hi_done

    la $t0, FallingColumn
    lw $t1, 0($t0)
    addi $t1, $t1, 1
    sw $t1, 0($t0)

    j hi_done
    
hi_drop:
    jal move_down 
    j hi_done

hi_quit:
    sw $zero, game_running
    j hi_done
    
hi_reset:
    jal reset_game
    j hi_done

hi_pause:
    lw $t0, game_state
    li $t1, 2               # STATE_PAUSE
    beq $t0, $t1, unpause

pause_now:
    li $t1, 2               # -> PAUSE
    sw $t1, game_state
    j hi_done

unpause:
    li $t1, 1               # -> PLAY
    sw $t1, game_state
    j hi_done

hi_done:
    lw $ra, 4($sp)
    addi $sp, $sp, 8
    jr $ra

##############################################################################
# PHYSICS AND LOGIC 
##############################################################################
# update_score
# Counts number of marked gems in marked_grid and increments
# the global score by that amount.
update_score:
    addi $sp, $sp, -8
    sw $ra, 4($sp)
    sw $s0, 0($sp)

    la $t0, marked_grid       # pointer
    li $t1, 144               # total cells
    li $t2, 0                 # match_count = 0

us_loop:
    beq $t1, $zero, us_done_count

    lb $t3, 0($t0)
    addi $t0, $t0, 1
    addi $t1, $t1, -1
    beq $t3, $zero, us_loop

    addi $t2, $t2, 1          # match_count++

    j us_loop

us_done_count:
    # load score and add match_count
    la $t4, score
    lw $t5, 0($t4)
    add $t5, $t5, $t2
    sw $t5, 0($t4)

    # return
    lw $s0, 0($sp)
    lw $ra, 4($sp)
    addi $sp, $sp, 8
    jr $ra

# update_high_score
# If score > high_score, updates high_score.
update_high_score:
    addi $sp, $sp, -8
    sw $ra, 4($sp)
    sw $s0, 0($sp)

    la $s0, score
    lw $t0, 0($s0)       # score

    la $s0, high_score
    lw $t1, 0($s0)       # high score

    ble $t0, $t1, uhs_done

    sw $t0, 0($s0)       # high_score = score

uhs_done:
    lw $s0, 0($sp)
    lw $ra, 4($sp)
    addi $sp, $sp, 8
    jr $ra


update_gravity:
    addi $sp, $sp, -8
    sw $ra, 4($sp)

    # Load counter / delay
    lw $t0, grav_counter
    lw $t1, GRAV_DELAY

    addi $t0, $t0, 1                # increment
    sw $t0, grav_counter

    blt $t0, $t1, ug_done           # not time yet
    # Time to fall -> reuse same function as S input
    jal move_down 
    
    sw $zero, grav_counter          # reset timer

ug_done:
    lw $ra, 4($sp)
    addi $sp, $sp, 8
    jr $ra

# can_move(dx $a0, dy $a1)          <-- collision detection 
#   v0 = 1 if movement valid
#   v0 = 0 otherwise
can_move:
    addi $sp, $sp, -8
    sw $ra, 4($sp)

    # Load FallingColumn
    la $t0, FallingColumn
    lw $t1, 0($t0)                  # x
    lw $t2, 4($t0)                  # y (top gem)

    # Apply change in direction
    add $t1, $t1, $a0               # new_x = x + dx
    add $t2, $t2, $a1               # new_y = y + dy

    # Bounds check using grid
    la $t3, grid
    lw $t4, GRID_COLS
    lw $t5, GRID_ROWS

    li $t6, 0                       # gem index (0 -> 1 -> 2)

cm_loop:
    beq $t6, 3, cm_ok               # all 3 gems checked ->  it's fine

    # target cell = (new_y + gem_index, new_x)
    add $t7, $t2, $t6               # row
    move $t8, $t1                   # col

    # r < 0? r >= ROWS?  (though grid border walls will block too)
    bltz $t7, cm_block
    bge $t7, $t5, cm_block
    bltz $t8, cm_block
    bge $t8, $t4, cm_block

    # compute grid index = r * COLS + c
    mul $t9, $t7, $t4
    add $t9, $t9, $t8

    add $s0, $t3, $t9
    lb $s1, 0($s0)

    # is cell not empty? 0 = empty, otherwise blocked (border or landed)
    bnez $s1, cm_block

    addi $t6, $t6, 1
    j cm_loop

cm_ok:
    li $v0, 1
    j cm_done

cm_block:
    li $v0, 0                       # cannot move

    # If dy == 1 (downward movement), set landing flag
    li $t7, 1
    bne $a1, $t7, cm_done           # if dy != 1 → no landing
    li $t8, 1
    sw $t8, landing_flag            # landing_flag = 1
    j cm_done 

cm_done:
    lw $ra, 4($sp)
    addi $sp, $sp, 8
    jr $ra

move_down:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    li $a0, 0
    li $a1, 1
    jal can_move
    beq $v0, $zero, md_done   # landing_flag already set

    # move down
    la $t0, FallingColumn
    lw $t1, 4($t0)
    addi $t1, $t1, 1
    sw $t1, 4($t0)

md_done:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# check_gravity_acceleration
# Called each frame. If global_timer >= next_gravity_tick:
#     GRAV_DELAY -= 1 (limited by mode)
#     next_gravity_tick += interval 
check_gravity_acceleration:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    # Load timers
    lw $t0, global_timer
    lw $t1, next_gravity_tick

    # Not time yet
    blt $t0, $t1, cga_done

    # Time to increase speed
    lw $t2, GRAV_DELAY
    addi $t2, $t2, -1                       # GRAV_DELAY -= 1

    # Load min based on difficulty
    lw $t3, game_difficulty

    beq $t3, $zero, cga_easy
    li $t4, 1
    beq $t3, $t4, cga_med

    # HARD
    la $t5, GRAV_MIN_HARD
    lw $t6, 0($t5)
    j cga_checkmin

cga_easy:
    la $t5, GRAV_MIN_EASY
    lw $t6, 0($t5)
    j cga_checkmin

cga_med:
    la $t5, GRAV_MIN_MED
    lw $t6, 0($t5)

cga_checkmin:
    # clamp: if newDelay < minDelay → set to min
    blt $t2, $t6, cga_set_min

    # store updated GRAV_DELAY
    sw $t2, GRAV_DELAY
    j cga_reschedule

cga_set_min:
    sw $t6, GRAV_DELAY

cga_reschedule:
    # next_gravity_tick += interval
    lw $t7, GRAV_TICK_INTERVAL
    add $t1, $t1, $t7
    sw $t1, next_gravity_tick

cga_done:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

##############################################################################
# LANDING SEQUENCE 
#############################################################################
# update_after_landing
# Called every frame after gravity + input.
# If landing_flag == 1 -> lock piece into grid, spawn next.
landing_sequence:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    lw $t0, landing_flag
    beq $t0, $zero, ual_done        # nothing to do

    # write falling column into the grid
    la $t1, FallingColumn
    lw $t2, 0($t1)                  # x
    lw $t3, 4($t1)                  # y

    la $t4, grid
    lw $t5, GRID_COLS

    # gem0
    lw $t6, 8($t1)
    mul $t7, $t3, $t5
    add $t7, $t7, $t2
    add $t7, $t4, $t7
    sb $t6, 0($t7)

    # gem1
    lw $t6, 12($t1)
    addi $t8, $t3, 1
    mul $t7, $t8, $t5
    add $t7, $t7, $t2
    add $t7, $t4, $t7
    sb $t6, 0($t7)

    # gem2
    lw $t6, 16($t1)
    addi $t8, $t3, 2
    mul $t7, $t8, $t5
    add $t7, $t7, $t2
    add $t7, $t4, $t7
    sb $t6, 0($t7)

    # reset landing flag
    sw $zero, landing_flag
    
    # RUN MATCHING + CASCADE!!!
    jal match_and_cascade

    # spawn next column
    jal init_column

ual_done:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


###############################################################
# MATCHING & CASCADE
###############################################################
# match_and_cascade
# Repeatedly:
#   - find_and_mark_all_matches
#   - clear_matched_gems
#   - apply_gravity
# until no more matches (v0 = 0 from find_and_mark_all_matches)
match_and_cascade:
    addi $sp,$sp,-4
    sw $ra,0($sp)

mc_loop:
    jal find_and_mark_all_matches   # v0 = 1 if any match, 0 else
    beq $v0,$zero, mc_done
    
    jal update_score

    jal clear_matched_gems
    jal apply_gravity
    j mc_loop

mc_done:
    lw $ra,0($sp)
    addi $sp,$sp,4
    jr $ra

# find_and_mark_all_matches
# - Clears marked_grid
# - Scan interior x=1...7, y=1...14
# - For every gem (value > 1) checks 4 directions:
#       - (1,0), (0,1), (1,1), (-1,1)
#   and marks runs of length >= 3 in marked_grid.
# Returns:
#   v0 = 1 if any match found
#   v0 = 0 otherwise
find_and_mark_all_matches:
    # save callee-saved regs + ra
    addi $sp,$sp,-40
    sw $ra,36($sp)
    sw $s0,32($sp)
    sw $s1,28($sp)
    sw $s2,24($sp)
    sw $s3,20($sp)
    sw $s4,16($sp)
    sw $s5,12($sp)
    sw $s6,8($sp)
    sw $s7,4($sp)

    # Clear *marked_grid* (144 bytes)
    la $t0, marked_grid
    li $t1, 144
fm_clear_loop:
    beq $t1, $zero, fm_clear_done
    sb $zero, 0($t0)
    addi $t0, $t0,1
    addi $t1, $t1,-1
    j fm_clear_loop
fm_clear_done:
    # Setup constants and match flag
    lw $s0, GRID_COLS                       # s0 = 9
    li $s5, 0                               # s5 = anyMatch (0 = no, 1 = yes)
    
    # Outer loops: y = 1...14, x = 1...7
    li $s2, 1                               # s2 = y
fm_y_loop:
    bgt $s2, 14, fm_y_done
    li $s3, 1                               # s3 = x
fm_x_loop:
    bgt $s3, 7, fm_x_done

    # index = y * GRID_COLS + x
    mul $t0, $s2, $s0
    add $t0, $t0, $s3
    la $t1, grid
    add $t1, $t1, $t0
    lb $t2, 0($t1)                          # t2 = cell value

    # skip empty (0) and border (1)
    li $t3, 1
    ble $t2, $t3, fm_next_cell

    # Start position and colour
    move $t6, $s3                            # start_x
    move $t7, $s2                            # start_y
    move $t8, $t2                            # run_color

    # Direction loop: 0..3 over dir_table
    li $t5, 0                                # dir_index = 0
fm_dir_loop:
    beq $t5, 4, fm_dir_done

    # Load dx,dy from dir_table[dir_index]
    li $t0, 8                               # each entry = 2 words = 8 bytes
    mul $t1, $t5, $t0                       # offset = dir_index * 8
    la $t9, dir_table
    add $t9, $t9, $t1
    lw $s6, 0($t9)                          # s6 = dx
    lw $s7, 4($t9)                          # s7 = dy

    # Initialize scan: run_len = 1 at (start_x,start_y)
    move $a0, $t6                           # cur_x
    move $a1, $t7                           # cur_y
    li $a3, 1                               # run_len

fm_scan_forward:
    # cur_x += dx; cur_y += dy
    add $a0, $a0, $s6
    add $a1, $a1, $s7

    # Bounds check: x in [1,7], y in [1,14]
    blt $a0, 1, fm_end_scan
    bgt $a0, 7, fm_end_scan
    blt $a1, 1, fm_end_scan
    bgt $a1, 14, fm_end_scan

    # Load next cell
    mul $t0, $a1, $s0
    add $t0, $t0, $a0
    la $t1, grid
    add $t1, $t1, $t0
    lb $t4, 0($t1)

    # Stop if different colour
    bne $t4, $t8, fm_end_scan

    # Same colour -> extend run
    addi $a3,$a3,1
    j fm_scan_forward

fm_end_scan:
    # If run_len >= 3, mark all cells in this run
    li $t0, 3
    blt $a3, $t0, fm_no_mark

    # Mark from (start_x,start_y) in direction (dx,dy), length run_len
    move $t0, $t6                               # mark_x
    move $t1, $t7                               # mark_y
    move $t2, $a3                               # remaining cells in run

fm_mark_loop:
    beq $t2,$zero, fm_mark_done

    # index = mark_y * GRID_COLS + mark_x
    mul $t3, $t1, $s0
    add $t3, $t3, $t0

    la $t4, marked_grid
    add $t4, $t4, $t3

    li $t9, 1
    sb $t9, 0($t4)

    # advance along direction
    add $t0, $t0, $s6
    add $t1, $t1, $s7
    addi $t2, $t2, -1
    j fm_mark_loop

fm_mark_done:
    li $s5, 1                   # anyMatch = 1

fm_no_mark:
    addi $t5, $t5, 1            # dir_index++
    j fm_dir_loop

fm_dir_done:
fm_next_cell:
    addi $s3, $s3, 1            # x++
    j fm_x_loop

fm_x_done:  
    addi $s2, $s2, 1            # y++
    j fm_y_loop

fm_y_done:
    move $v0, $s5               # return anyMatch in v0

    # restore regs and return
    lw $ra,36($sp)
    lw $s0,32($sp)
    lw $s1,28($sp)
    lw $s2,24($sp)
    lw $s3,20($sp)
    lw $s4,16($sp)
    lw $s5,12($sp)
    lw $s6,8($sp)
    lw $s7,4($sp)
    addi $sp,$sp,40
    jr $ra

# clear_matched_gems
# - For each cell i:
#     if marked_grid[i] != 0 → grid[i] = 0 (TILE_EMPTY)
clear_matched_gems:
    la $t0, grid
    la $t1, marked_grid
    li $t2, 144

clm_loop:
    beq $t2, $zero, clm_done

    lb $t3, 0($t1)
    beq $t3, $zero, clm_skip

    sb $zero, 0($t0)                                 # clear gem

clm_skip:
    addi $t0, $t0, 1
    addi $t1, $t1, 1
    addi $t2, $t2, -1
    j clm_loop

clm_done:
    jr $ra

# apply_gravity
# - For each interior column x=1...7:
#     scan from y=14 down to 1:
#       collect cells with value > 1 (gems),
#       write them downwards starting at y=14,
#       fill remaining cells above with 0.
apply_gravity:
    lw $t9, GRID_COLS      # t9 = GRID_COLS (9)

    li $t0,1               # t0 = x, columns 1..7
ag_col_loop:
    bgt $t0,7, ag_grav_done

    li $t1,14              # write_y = 14
    li $t2,14              # read_y  = 14

ag_read_loop:
    blt $t2,1, ag_fill      # when read_y < 1, go fill above

    # index = read_y * GRID_COLS + x
    mul $t3,$t2,$t9
    add $t3,$t3,$t0
    la $t4,grid
    add $t4,$t4,$t3
    lb $t5,0($t4)          # t5 = cell value at (x,read_y)

    # empty or border (<=1) → skip
    li $t6,1
    ble $t5,$t6, ag_next_read

    # we have a gem (value > 1) → write at (x,write_y)
    mul $t6,$t1,$t9
    add $t6,$t6,$t0
    la $t7,grid
    add $t7,$t7,$t6
    sb $t5,0($t7)

    # if write_y != read_y, clear old spot
    bne $t1,$t2, ag_clear_old
    j ag_written

ag_clear_old:
    sb $zero,0($t4)

ag_written:
    addi $t1,$t1,-1          # write_y--

ag_next_read:
    addi $t2,$t2,-1          # read_y--
    j ag_read_loop

ag_fill:
    # fill any space above write_y with empty (0)
    li $t2,1
ag_fill_loop:
    bgt $t2,$t1, ag_next_col

    mul $t3,$t2,$t9
    add $t3,$t3,$t0
    la $t4,grid
    add $t4,$t4,$t3
    sb $zero,0($t4)

    addi $t2,$t2,1
    j ag_fill_loop

ag_next_col:
    addi $t0,$t0,1           # x++
    j ag_col_loop

ag_grav_done:
    jr $ra

##############################################################################
# GRAPHICS 
##############################################################################

render_frame: 
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    jal clear_screen
    jal draw_grid
    jal draw_falling_column
    jal draw_score_display
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# draw_grid Renders the entire 9x16 grid (including borders) on screen.
# For each grid cell:
#   - load tile index (byte)
#   - lookup color in color_table
#   - draw to bitmap at:
#         screen_x = PLAYFIELD_X + col
#         screen_y = PLAYFIELD_Y + row
draw_grid:
    # epilogue 
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    # Load constants
    lw $t0, ADDR_DSPL               # bitmap base address
    lw $t1, BITMAP_WIDTH            # bitmap width in tiles (32)

    lw $t2, PLAYFIELD_X             # screen X offset
    lw $t3, PLAYFIELD_Y             # screen Y offset

    lw $t4, GRID_ROWS               # rows = 16
    lw $t5, GRID_COLS               # cols = 9

    la $t6, grid                    # pointer to grid[]
    la $t7, colour_table            # pointer to color table

    li $t8, 0                       # r = 0

dg_row_loop:
    beq $t8, $t4, dg_done           # stop if r == GRID_ROWS
    li $t9, 0                       # c = 0
    
dg_col_loop:
    beq $t9, $t5, dg_next_row      # stop if c == GRID_COLS

    # Compute grid index: index = r * COLS + c
    mul $s0, $t8, $t5         # r * COLS
    add $s0, $s0, $t9         # + c

    add $s1, $t6, $s0         # cell address = grid + index
    lb $s2, 0($s1)           # load tile index (0..7)


    # Lookup color in color_table
    # offset = tile_index * 4
    # color = *(color_table + offset)
    sll $s3, $s2, 2           # tile_index * 4
    add $s3, $t7, $s3         # color_table + offset
    lw $s4, 0($s3)           # load actual color

    # Convert (r, c) to screen (y, x)
    # screen_x = PLAYFIELD_X + c
    add $s6, $t2, $t9
    # screen_y = PLAYFIELD_Y + r
    add $s5, $t3, $t8
    
    # Compute bitmap memory offset
    # screen_index = (screen_y * GRID_WIDTH + screen_x) * 4
    mul $s7, $s5, $t1         # y * GRID_WIDTH
    add $s7, $s7, $s6         # + x
    sll $s7, $s7, 2           # * 4 bytes per pixel

    add $s7, $t0, $s7         # final address

    sw $s4, 0($s7)           # draw pixel color

    # Next column
    addi $t9, $t9, 1
    j dg_col_loop

dg_next_row:
    addi $t8, $t8, 1
    j dg_row_loop

dg_done:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# clear screen 
clear_screen:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    lw $t0, ADDR_DSPL               # base address of bitmap
    lw $t1, BITMAP_WIDTH            # width in units
    lw $t2, BITMAP_HEIGHT           # height in units

    la $t3, colour_table            # color table base
    lw $t4, 0($t3)                  # background color = color_table[0]
    
    # total pixels = width * height 
    mul $t5, $t1, $t2               # total cells = 32 * 32 = 1024
    li $t6, 0                       # loop index = 0

cls_loop:
    beq $t6, $t5, cls_done   # stop when index == total_pixels

    sll $t7, $t6, 2                 # offset = index * 4 bytes
    add $t8, $t0, $t7               # pixel_address = base + offset
    sw $t4, 0($t8)                  # write background color

    addi $t6, $t6, 1
    j cls_loop

cls_done:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# draw_falling_column (dfc); draws the active column onto the bitmap
draw_falling_column:
    addi $sp, $sp, -20
    sw   $ra, 16($sp)
    
    # Load bitmap and constants
    lw $t0, ADDR_DSPL
    lw $t1, BITMAP_WIDTH        # 32
    lw $t2, PLAYFIELD_X
    lw $t3, PLAYFIELD_Y
    la $t4, colour_table

    # Load falling column struct
    la $t5, FallingColumn               # base of FallingColumn struct
    lw $t6, 0($t5)                      # piece_x
    lw $t7, 4($t5)                      # piece_y

    # Load gem indices into temp array on stack
    lw $t8, 8($t5)                     # gem0 -> ($sp+0)
    sw $t8, 0($sp)
    lw $t9, 12($t5)                     # gem1 -> ($sp+4)
    sw $t9, 4($sp)
    lw $s0, 16($t5)                     # gem2 -> ($sp+8)
    sw $s0, 8($sp)

    # Loop through 3 gems
    li $s1, 0                           # i = 0

dfc_loop:
    beq $s1, 3, dfc_done               # stop when i == 3

    # Load gem index = gem[i]
    sll $s2, $s1, 2                     # offset = i * 4
    add $s3, $sp, $s2
    lw $s4, 0($s3)                      # s4 = gem index (2..7)

    # Compute screen coords
    add $s5, $t2, $t6                   # screen_x = PFX + piece_x
    add $s6, $t3, $t7                   # screen_y = PFY + piece_y
    add $s6, $s6, $s1                   # + i (0, 1, or 2)

    # Compute bitmap address
    mul $s7, $s6, $t1                   # y * width
    add $s7, $s7, $s5                   # + x
    sll $s7, $s7, 2                     # * 4
    add $s7, $s7, $t0                   # final pixel address

    # Load actual color from color_table
    sll $t8, $s4, 2           
    add $t8, $t8, $t4
    lw $t9, 0($t8)

    # Write color
    sw $t9, 0($s7)

    # next gem
    addi $s1, $s1, 1
    j dfc_loop

dfc_done:
    lw $ra, 16($sp)
    addi $sp, $sp, 20
    jr $ra

##############################################################################
# draw_bitmap_3x5
# Draw a single 3×5 glyph at unit coordinates (x, y).
# Args:
#   $a0 = x (0...31)
#   $a1 = y (0...31)
#   $a2 = address of 5-word bitmap (glyph_A, glyph_C, ...)
##############################################################################
draw_bitmap_3x5:
    la $t0, ADDR_DSPL
    lw $t0, 0($t0)              # base = 0x10008000
    li $t1, 0xFF0FF             # cyan

    # Bounds guards: glyph must fit (width=3, height=5)
    beq $a2, $zero, db3x5_glyph_done
    li $t2, 30
    slt $t3, $t2, $a0            # 30 < x  => x >= 31
    bne $t3, $zero, db3x5_glyph_done
    li $t2, 28
    slt $t3, $t2, $a1            # 28 < y  => y >= 29
    bne $t3, $zero, db3x5_glyph_done

    li $t2, 0                   # row = 0
db3x5_row_loop:
    slti $t3, $t2, 5
    beq $t3, $zero, db3x5_glyph_done

    sll $t6, $t2, 2              # &row = a2 + row*4
    addu $t6, $a2, $t6
    lw $t5, 0($t6)              # pattern (3-bit)

    li $t4, 4                   # mask 4→2→1
    li $t3, 0                   # col = 0
db3x5_col_loop:
    slti $t6, $t3, 3
    beq $t6, $zero, db3x5_next_row

    and $t7, $t5, $t4
    beq $t7, $zero, db3x5_skip_plot

    # X = x + col 
    # Y = y + row
    addu $t7, $a0, $t3
    addu $t8, $a1, $t2

    # addr = base + ((((Y * 32) + X) * 4))
    sll $t9, $t8, 5              # Y * 32
    addu $t9, $t9, $t7            # + X
    sll $t9, $t9, 2              # * 4 bytes
    addu $t9, $t9, $t0            # + base
    sw $t1, 0($t9)              # write color

db3x5_skip_plot:
    addiu $t3, $t3, 1
    srl $t4, $t4, 1
    j db3x5_col_loop

db3x5_next_row:
    addiu $t2, $t2, 1
    j db3x5_row_loop

db3x5_glyph_done:
    jr $ra
    
    
##############################################################################
# draw_glyph_5x7: draw a 5×7 bitmap at (x,y) in RED.
# Args:
#   $a0 = x (unit coordinate, 0..31)
#   $a1 = y (unit coordinate, 0..31)
#   $a2 = address of 7-word bitmap (rows 0..6), each row is a 5-bit mask.
# Uses only $t0-$t9 (caller-saved).
##############################################################################
draw_glyph_5x7:
    # Load display base and color
    la $t0, ADDR_DSPL
    lw $t0, 0($t0)              # base = 0x10008000
    li $t1, 0xFF0000

    # Guard: null bitmap or out-of-bounds (glyph must fully fit: x<=26, y<=24)
    beq $a2, $zero, db5x7_glyph_done
    li $t2, 27
    slt $t3, $t2, $a0            # 27 < x  => x >= 28 (too far right)
    bne $t3, $zero, db5x7_glyph_done
    li $t2, 25
    slt $t3, $t2, $a1            # 25 < y  => y >= 26 (too low)
    bne $t3, $zero, db5x7_glyph_done

    # Row loop: 0..6
    li $t2, 0
db5x7_row_loop:
    slti $t3, $t2, 7
    beq $t3, $zero, db5x7_glyph_done

    # row_ptr = a2 + row*4 ; load 5-bit pattern
    sll $t6, $t2, 2
    addu $t6, $a2, $t6
    lw $t5, 0($t6)

    # Column loop: mask 16→8→4→2→1 (left→right)
    li $t4, 16
    li $t3, 0
db5x7_col_loop:
    slti $t6, $t3, 5
    beq $t6, $zero, db5x7_next_row

    and $t7, $t5, $t4
    beq $t7, $zero, db5x7_skip_plot

    # X = x + col ; Y = y + row
    addu $t7, $a0, $t3
    addu $t8, $a1, $t2

    # addr = base + ((((Y * 32) + X) * 4))
    sll $t9, $t8, 5              # Y * 32
    addu $t9, $t9, $t7            # + X
    sll $t9, $t9, 2              # * 4 bytes
    addu $t9, $t9, $t0            # + base
    sw $t1, 0($t9)              # store color

db5x7_skip_plot:
    addiu $t3, $t3, 1
    srl $t4, $t4, 1
    j db5x7_col_loop

db5x7_next_row:
    addiu $t2, $t2, 1
    j db5x7_row_loop

db5x7_glyph_done:
    jr $ra
##############################################################################
##############################################################################
# Game Pages 
##############################################################################
##############################################################################

##############################################################################
# menu
##############################################################################
menu_state:
    j menu_loop          # entry point to bitmap menu

menu_loop:
menu_loop_start:

    jal draw_menu_screen     # your full bitmap menu
    jal menu_handle_input    # only 0/1/2/Q allowed

    # exit back to dispatcher ONLY if we changed state
    lw $t0, game_state
    li $t1, 0                # STATE_MENU
    bne $t0, $t1, menu_exit

    # small delay (~16ms)
    li $v0, 32
    li $a0, 16
    syscall

    j menu_loop_start

menu_exit:
    j state_dispatch
    
# MENU INPUT HANDLER
menu_handle_input:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    # poll keyboard MMIO
    lw $t0, ADDR_KBRD
    lw $t1, 0($t0)
    beq $t1, $zero, mhi_done      # no key

    lw $t2, 4($t0)                # ASCII key

    # EASY (0)
    lw $t3, ASCII_0
    beq $t2, $t3, menu_set_easy

    # MEDIUM (1)
    lw $t3, ASCII_1
    beq $t2, $t3, menu_set_med

    # HARD (2)
    lw $t3, ASCII_2
    beq $t2, $t3, menu_set_hard

    # QUIT (Q)
    lw $t3, ASCII_Q
    beq $t2, $t3, menu_set_quit

    j mhi_done


menu_set_easy:
    li $t4, 0
    sw $t4, game_difficulty
    j menu_begin_play

menu_set_med:
    li $t4, 1
    sw $t4, game_difficulty
    j menu_begin_play

menu_set_hard:
    li $t4, 2
    sw $t4, game_difficulty
    j menu_begin_play

menu_begin_play:
    jal init_game
    li $t5, 1             # STATE_PLAY
    sw $t5, game_state
    j mhi_done

menu_set_quit:
    sw $zero, game_running
    J game_exit
    j mhi_done

mhi_done:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

##############################################################################
# MENU BITMAP RENDERER
##############################################################################
draw_menu_screen:
    addi $sp, $sp, -16
    sw $ra, 12($sp)
    sw $s0, 8($sp)
    sw $s1, 4($sp)
    sw $s2, 0($sp)

    # clear background
    jal clear_screen

    ########################
    # Title: COLUMNS
    ########################
    li $s1, 4          # Y for title
    li $s0, 2          # X start
    li $s2, 4          # spacing (3 wide + 1 gap)

    # C
    move $a0, $s0
    move $a1, $s1
    la $a2, glyph_C
    jal draw_bitmap_3x5

    # O
    addu $s0, $s0, $s2     # <-- FIXED
    move $a0, $s0
    move $a1, $s1
    la $a2, glyph_O
    jal draw_bitmap_3x5

    # L
    addu $s0, $s0, $s2
    move $a0, $s0
    move $a1, $s1
    la $a2, glyph_L
    jal draw_bitmap_3x5

    # U
    addu $s0, $s0, $s2
    move $a0, $s0
    move $a1, $s1
    la $a2, glyph_U
    jal draw_bitmap_3x5

    # M
    addu $s0, $s0, $s2
    move $a0, $s0
    move $a1, $s1
    la $a2, glyph_M
    jal draw_bitmap_3x5

    # N
    addu $s0, $s0, $s2
    move $a0, $s0
    move $a1, $s1
    la $a2, glyph_N
    jal draw_bitmap_3x5

    # S
    addu $s0, $s0, $s2
    move $a0, $s0
    move $a1, $s1
    la $a2, glyph_S
    jal draw_bitmap_3x5


    ########################
    # EASY
    ########################
    li $s1, 12         # Y
    li $s0, 6          # X start

    # E
    move $a0, $s0
    move $a1, $s1
    la $a2, glyph_E
    jal draw_bitmap_3x5

    # A
    addu $s0, $s0, $s2
    move $a0, $s0
    move $a1, $s1
    la $a2, glyph_A
    jal draw_bitmap_3x5

    # S
    addu $s0, $s0, $s2
    move $a0, $s0
    move $a1, $s1
    la $a2, glyph_S
    jal draw_bitmap_3x5

    # Y
    addu $s0, $s0, $s2
    move $a0, $s0
    move $a1, $s1
    la $a2, glyph_Y
    jal draw_bitmap_3x5


    ########################
    # MED
    ########################
    li $s1, 18
    li $s0, 6

    # M
    move $a0, $s0
    move $a1, $s1
    la $a2, glyph_M
    jal draw_bitmap_3x5

    # E
    addu $s0, $s0, $s2
    move $a0, $s0
    move $a1, $s1
    la $a2, glyph_E
    jal draw_bitmap_3x5

    # D
    addu $s0, $s0, $s2
    move $a0, $s0
    move $a1, $s1
    la $a2, glyph_D
    jal draw_bitmap_3x5


    ########################
    # HARD
    ########################
    li $s1, 24
    li $s0, 6

    # H
    move $a0, $s0
    move $a1, $s1
    la $a2, glyph_H
    jal draw_bitmap_3x5

    # A
    addu $s0, $s0, $s2
    move $a0, $s0
    move $a1, $s1
    la $a2, glyph_A
    jal draw_bitmap_3x5

    # R
    addu $s0, $s0, $s2
    move $a0, $s0
    move $a1, $s1
    la $a2, glyph_R
    jal draw_bitmap_3x5

    # D
    addu $s0, $s0, $s2
    move $a0, $s0
    move $a1, $s1
    la $a2, glyph_D
    jal draw_bitmap_3x5

    # restore callee-saved
    lw $s2, 0($sp)
    lw $s1, 4($sp)
    lw $s0, 8($sp)
    lw $ra,12($sp)
    addi $sp, $sp, 16
    jr $ra

##############################################################################
# PAUSE STATE (bitmap)
##############################################################################

pause_state:
    # Draw once per frame
    jal draw_pause_screen
    jal pause_handle_input

    # stay in pause until state changes
    lw $t0, game_state
    li $t1, 2                 # still STATE_PAUSE ?
    beq $t0, $t1, pause_loop_delay

    # otherwise return to dispatcher
    j state_dispatch

pause_loop_delay:
    # small frame delay
    li $v0, 32
    li $a0, 16
    syscall
    j pause_state

##############################################################################
# PAUSE INPUT HANDLER (UPDATED)
#   Allowed keys:
#     P = unpause (resume play)
#     B = back to menu
#     Q = quit game
##############################################################################
pause_handle_input:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    lw $t0, ADDR_KBRD
    lw $t1, 0($t0)
    beq $t1, $zero, phi_done        # no key pressed

    lw $t2, 4($t0)                 # ASCII key

    # P = unpause
    lw $t3, ASCII_P
    beq $t2, $t3, phi_unpause

    # B = back to menu
    lw $t3, ASCII_B
    beq $t2, $t3, phi_back

    # Q = quit
    lw $t3, ASCII_Q
    beq $t2, $t3, phi_quit

    j phi_done

phi_unpause:
    li $t4, 1                       # STATE_PLAY
    sw $t4, game_state
    j phi_done

phi_back:
    # Reset entire game (board, gravity, flags)
    jal reset_game
    # Return to menu state
    sw $zero, game_state            # STATE_MENU = 0
    j phi_done

phi_quit:
    sw $zero, game_running
    li $t4, -1
    sw $t4, game_state

    j phi_done

phi_done:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

##############################################################################
# DRAW PAUSE SCREEN 
##############################################################################
draw_pause_screen:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    # clear background
    jal clear_screen

    # color for pause bars
    li $t1, 0x404040       # dark grey
    lw $t0, ADDR_DSPL

    # ---------- Bar 1 ----------
    li $t2, 8              # row start
pause_bar1_row:
    li $t3, 24
    beq $t2, $t3, pause_bar1_done

    li $t4, 12             # col start
pause_bar1_col:
    li $t5, 15
    beq $t4, $t5, pause_bar1_next_row

    # addr = base + ((row*32 + col) * 4)
    sll $a0, $t2, 5
    addu $a0, $a0, $t4
    sll $a0, $a0, 2
    addu $a0, $a0, $t0
    sw $t1, 0($a0)

    addiu $t4, $t4, 1
    j pause_bar1_col

pause_bar1_next_row:
    addiu $t2, $t2, 1
    j pause_bar1_row

pause_bar1_done:

    # ---------- Bar 2 ----------
    li $t2, 8
pause_bar2_row:
    li $t3, 24
    beq $t2, $t3, pause_done

    li $t4, 17
pause_bar2_col:
    li $t5, 20
    beq $t4, $t5, pause_bar2_next_row

    sll $a0, $t2, 5
    addu $a0, $a0, $t4
    sll $a0, $a0, 2
    addu $a0, $a0, $t0
    sw $t1, 0($a0)

    addiu $t4, $t4, 1
    j pause_bar2_col

pause_bar2_next_row:
    addiu $t2, $t2, 1
    j pause_bar2_row

pause_done:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra



###############################################################
# GAME OVER STATE
###############################################################

# game_over_handler:
#   Called from PLAY loop once when game_over_flag is set.
#   Simply switches to GAME OVER state.
game_over_handler:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)
    jal update_high_score
    li $t0, 3                   # STATE_OVER
    sw $t0, game_state
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

game_over_state:
    jal draw_game_over_screen
    jal game_over_handle_input

    # Stay until state changes
    lw $t0, game_state
    li $t1, 3
    beq $t0, $t1, go_delay
    j state_dispatch          # state changed → exit

go_delay:
    li $v0,32
    li $a0,16
    syscall
    j game_over_state

game_over_handle_input:
    addi $sp,$sp,-4
    sw $ra,0($sp)

    lw $t0, ADDR_KBRD
    lw $t1, 0($t0)
    beq $t1, $zero, gohi_done

    lw $t2, 4($t0)

    # R = Restart
    lw $t3, ASCII_R
    beq $t2,$t3, gohi_restart

    # B = Back to menu
    lw $t3, ASCII_B
    beq $t2,$t3, gohi_back

    # Q = Quit
    lw $t3, ASCII_Q
    beq $t2,$t3, gohi_quit

    j gohi_done

gohi_restart:
    jal reset_game
    li $t4,1
    sw $t4, game_state
    j gohi_done

gohi_back:
    jal reset_game
    sw $zero, game_state
    j gohi_done

gohi_quit:
    sw $zero, game_running
    li $t4,-1
    sw $t4, game_state
    j gohi_done

gohi_done:
    lw $ra,0($sp)
    addi $sp,$sp,4
    jr $ra

draw_game_over_screen:
    addi $sp,$sp,-16
    sw $ra,12($sp)
    sw $s0, 8($sp)
    sw $s1, 4($sp)
    sw $s2, 0($sp)

    jal clear_screen

    # spacing and initial positions
    li $s2, 6          # spacing = 5-wide glyph + 1 gap
    li $s1, 8          # Y for "GAME"
    li $s0, 6          # X start for "GAME"

    # ----- "GAME" -----
    # G
    move $a0, $s0
    move $a1, $s1
    la $a2, glyph5x7_G
    jal draw_glyph_5x7

    # A
    addu $s0, $s0, $s2
    move $a0, $s0
    move $a1, $s1
    la $a2, glyph5x7_A
    jal draw_glyph_5x7

    # M
    addu $s0, $s0, $s2
    move $a0, $s0
    move $a1, $s1
    la $a2, glyph5x7_M
    jal draw_glyph_5x7

    # E
    addu $s0, $s0, $s2
    move $a0, $s0
    move $a1, $s1
    la $a2, glyph5x7_E
    jal draw_glyph_5x7

    # ----- "OVER" -----
    li $s1, 16         # second row Y
    li $s0, 6          # reset X

    # O
    move $a0, $s0
    move $a1, $s1
    la $a2, glyph5x7_O
    jal draw_glyph_5x7

    # V
    addu $s0, $s0, $s2
    move $a0, $s0
    move $a1, $s1
    la $a2, glyph5x7_V
    jal draw_glyph_5x7

    # E
    addu $s0, $s0, $s2
    move $a0, $s0
    move $a1, $s1
    la $a2, glyph5x7_E
    jal draw_glyph_5x7

    # R
    addu $s0, $s0, $s2
    move $a0, $s0
    move $a1, $s1
    la $a2, glyph5x7_R
    jal draw_glyph_5x7

    # restore callee-saved regs
    lw $s2, 0($sp)
    lw $s1, 4($sp)
    lw $s0, 8($sp)
    lw $ra,12($sp)
    addi $sp,$sp,16
    jr $ra
    
##############################################################################
# score gui 
##############################################################################

# draw_score_display
draw_score_display:
    addi $sp,$sp,-16
    sw $ra,12($sp)
    sw $s0,8($sp)
    sw $s1,4($sp)
    sw $s2,0($sp)

    ###### DRAW HIGH SCORE LABEL ######
    li $a0, 1          # x for HI:
    li $a1, 1          # y
    jal draw_hi_label

    ###### DRAW HIGH SCORE DIGITS ######
    la $t1, high_score
    lw $t2, 0($t1)

    li $a0, 11                      # after H (4), I (4), colon (3), slight gap (1)
    li $a1, 1
    move $a2, $t2
    jal draw_number_3digits

    ###############################
    # 2. SCORE AT BOTTOM LEFT
    ###############################
    la $t0, score
    lw $t1, 0($t0)

    li $a0, 20         # x for hundreds
    li $a1, 26         # y for all
    move $a2, $t1
    jal draw_number_3digits

    ###############################
    # Restore
    ###############################
    lw   $s2,0($sp)
    lw   $s1,4($sp)
    lw   $s0,8($sp)
    lw   $ra,12($sp)
    addi $sp,$sp,16
    jr $ra

# draw_number_3digits
##############################################################################
# draw_number_3digits
# Args:
#   a0 = base x  (for hundreds)
#   a1 = base y  (for all digits)
#   a2 = number  (0–999)
##############################################################################
draw_number_3digits:
    addi $sp,$sp,-28
    sw $ra,24($sp)
    sw $s0,20($sp)
    sw $s1,16($sp)
    sw $s2,12($sp)
    sw $s3, 8($sp)
    sw $s4, 4($sp)

    # Save base x,y
    move $s0, $a0          # base x
    move $s1, $a1          # base y
    move $t9, $a2          # n (use temp while computing)

    #### compute hundreds ####
    li $t0, 100
    div $t9, $t0
    mflo $s2               # hundreds digit

    #### tens & ones ####
    li $t0, 10
    div $t9, $t0
    mflo $t1               # floor(n/10)
    mfhi $s4               # ones digit

    li $t0, 10
    div $t1, $t0
    mfhi $s3               # tens digit = (n/10) % 10

    #### draw hundreds ####
    move $a0, $s0          # x = base x
    move $a1, $s1          # y = base y
    move $a2, $s2          # digit
    jal draw_digit_from_value

    #### draw tens ####
    addi $a0, $s0, 4       # x + 4
    move $a1, $s1
    move $a2, $s3
    jal draw_digit_from_value

    #### draw ones ####
    addi $a0, $s0, 8       # x + 8
    move $a1, $s1
    move $a2, $s4
    jal draw_digit_from_value

    # Restore
    lw $s4, 4($sp)
    lw $s3, 8($sp)
    lw $s2,12($sp)
    lw $s1,16($sp)
    lw $s0,20($sp)
    lw $ra,24($sp)
    addi $sp,$sp,28
    jr $ra

draw_digit_from_value:
    beq $a2, $zero, draw_0
    li $t0, 1
    beq $a2, $t0, draw_1
    li $t0, 2
    beq $a2, $t0, draw_2
    li $t0, 3
    beq $a2, $t0, draw_3
    li $t0, 4
    beq $a2, $t0, draw_4
    li $t0, 5
    beq $a2, $t0, draw_5
    li $t0, 6
    beq $a2, $t0, draw_6
    li $t0, 7
    beq $a2, $t0, draw_7
    li $t0, 8
    beq $a2, $t0, draw_8
    # else:
    j draw_9


draw_0:
    addiu $sp, $sp, -4
    sw $ra, 0($sp)
    la $a2, glyph0
    jal draw_bitmap_3x5
    lw $ra, 0($sp)
    addiu $sp, $sp, 4
    jr $ra

draw_1:
    addiu $sp, $sp, -4
    sw $ra, 0($sp)
    la $a2, glyph1
    jal draw_bitmap_3x5
    lw $ra, 0($sp)
    addiu $sp, $sp, 4
    jr $ra

draw_2:
    addiu $sp, $sp, -4
    sw $ra, 0($sp)
    la $a2, glyph2
    jal draw_bitmap_3x5
    lw $ra, 0($sp)
    addiu $sp, $sp, 4
    jr $ra

draw_3:
    addiu $sp, $sp, -4
    sw $ra, 0($sp)
    la $a2, glyph3
    jal draw_bitmap_3x5
    lw $ra, 0($sp)
    addiu $sp, $sp, 4
    jr $ra

draw_4:
    addiu $sp, $sp, -4
    sw $ra, 0($sp)
    la $a2, glyph4
    jal draw_bitmap_3x5
    lw $ra, 0($sp)
    addiu $sp, $sp, 4
    jr $ra

draw_5:
    addiu $sp, $sp, -4
    sw $ra, 0($sp)
    la $a2, glyph5
    jal draw_bitmap_3x5
    lw $ra, 0($sp)
    addiu $sp, $sp, 4
    jr $ra

draw_6:
    addiu $sp, $sp, -4
    sw $ra, 0($sp)
    la $a2, glyph6
    jal draw_bitmap_3x5
    lw $ra, 0($sp)
    addiu $sp, $sp, 4
    jr $ra

draw_7:
    addiu $sp, $sp, -4
    sw $ra, 0($sp)
    la $a2, glyph7
    jal draw_bitmap_3x5
    lw $ra, 0($sp)
    addiu $sp, $sp, 4
    jr $ra

draw_8:
    addiu $sp, $sp, -4
    sw $ra, 0($sp)
    la $a2, glyph8
    jal draw_bitmap_3x5
    lw $ra, 0($sp)
    addiu $sp, $sp, 4
    jr $ra

draw_9:
    addiu $sp, $sp, -4
    sw $ra, 0($sp)
    la $a2, glyph9
    jal draw_bitmap_3x5
    lw $ra, 0($sp)
    addiu $sp, $sp, 4
    jr $ra

draw_hi_label:
    # expects a0 = base x, a1 = base y
    addi $sp,$sp,-8
    sw $ra,4($sp)
    sw $s0,0($sp)

    move $s0, $a0      # base x
    # H
    move $a0, $s0
    move $a1, $a1
    la $a2, glyph_H
    jal draw_bitmap_3x5   

    # I
    addi $s0, $s0, 4
    move $a0, $s0
    move $a1, $a1
    la $a2, glyph_I
    jal draw_bitmap_3x5

    # :
    addi $s0, $s0, 3  
    move $a0, $s0
    move $a1, $a1
    la $a2, glyph_COLON
    jal draw_bitmap_3x5

    lw $s0,0($sp)
    lw $ra,4($sp)
    addi $sp,$sp,8
    jr $ra

##############################################################################
# random colour generator2
##############################################################################
rand_color_index:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    li $v0, 42              # syscall: random int < a1
    li $a0, 0               # RNG id 
    li $a1, 6               # want 0..5
    syscall

    addi $a0, $a0, 2        # convert to 2..7

    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
    
##############################################################################
# EXIT GAME 
##############################################################################
game_exit: 
    li  $v0, 10
    syscall