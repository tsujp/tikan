# Desired Tests

Rather than keeping track of wanted tests within test files and having to open say 6 different files to check all have the same we can trust ourselves to keep this file up to date (famous last words) with the tests we want and whether or not we've implemented them. Ideally in the future this is automated.

## All Pieces

### Move validations

#### Basic pattern
  e.g. a rook should only be able to move orthogonally.

  - [ ] Knight.
  - [ ] Bishop.
  - [ ] Rook.
  - [ ] Queen.
  - [ ] King.
  - [ ] Pawn.


##### Empty board
  Tests which logically stress the implementation; typically by making moves at the edges of the board. Essentially a wide range gamut test on move patterns.

  - [ ] Knight.
  - [ ] Bishop.
  - [ ] Rook.
  - [ ] Queen.
  - [ ] King.
  - [ ] Pawn.


##### Complex scenarios
  Move tests under complex scenarios (pieces on the board) such as obstructions being in the way.

  - [ ] Knight.
  - [ ] Bishop.
  - [ ] Rook.
  - [ ] Queen.
  - [ ] King.
  - [ ] Pawn.

## Logic

### LS1B

  - [x] LS1B happy path.
  - [x] LS1B sad path.

### MS1B

  - [ ] MS1B happy path.
  - [ ] LS1B sad path.

### Diagonals

#### Masks
  Diag masking is the basis for all diag (diagonal and anti-diagonal) sliding piece movement (bishop, queen, king), so these masks must be correct without weird wrapping or edge-artifacting.

  - [x] Diagonal masks for every starting edge square.
  - [x] Anti-diagonal masks for every starting edge square.

#### Same-diagonal
  Whether two given square indices are on the same diag forms the basis of computing the required diag mask.

  - [x] Same diagonal and NOT same anti-diagonal.
  - [x] Same anti-diagonal and NOT same diagonal.
