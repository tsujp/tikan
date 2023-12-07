# Desired Tests

Rather than keeping track of wanted tests within test files and having to open say 6 different files to check all have the same we can trust ourselves to keep this file up to date (famous last words) with the tests we want and whether or not we've implemented them. Ideally in the future this is automated.

## All Pieces

<table>
  <thead>
    <tr>
      <td rowspan="2" colspan="2" />
      <th scope="colgroup" />
      <th scope="colgroup" colspan="3">Sliders</th>
    </tr>
    <tr>
      <th scope="col">Knight</th>
      <th scope="col">Bishop / Rook / Queen</th>
      <th scope="col">King</th>
      <th scope="col">Pawn</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th scope="rowgroup" rowspan="2">Pattern</th>
      <th scope="row">Empty board</th>
      <td>✅</td>
      <td>❌</td>
      <td>✅</td>
      <td>ON IT</td>
    </tr>
    <tr>
      <th scope="row">Dense board</th>
      <td>✅</td>
      <td>❌</td>
      <td>✅</td>
      <td>❌</td>
    </tr>
    <tr>
      <th scope="rowgroup" rowspan="2">Blocked</th>
      <th scope="row">Minimal board</th>
      <td>✅</td>
      <td>❌</td>
      <td>❌</td>
      <td>❌</td>
    </tr>
    <tr>
      <th scope="row">Dense board</th>
      <td>✅</td>
      <td>❌</td>
      <td>✅</td>
      <td>❌</td>
    </tr>
    <tr>
      <th scope="rowgroup" rowspan="5">Special</th>
      <th scope="row">King's side castle</th>
      <td>-</td>
      <td>-</td>
      <td>❌</td>
      <td>-</td>
    </tr>
    <tr>
      <th scope="row">Queen's side castle</th>
      <td>-</td>
      <td>-</td>
      <td>❌</td>
      <td>-</td>
    </tr>
    <tr>
      <th scope="row">Promotion</th>
      <td>-</td>
      <td>-</td>
      <td>-</td>
      <td>❌</td>
    </tr>
    <tr>
      <th scope="row">En-passant capture</th>
      <td>-</td>
      <td>-</td>
      <td>-</td>
      <td>❌</td>
    </tr>
    <tr>
      <th scope="row">En-passant target</th>
      <td>-</td>
      <td>-</td>
      <td>-</td>
      <td>❌</td>
    </tr>
  </tbody>
</table>

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
