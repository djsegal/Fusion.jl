"""
    Tape_L()

Length of tape per cable [m].
"""
function Tape_L()

  cur_Tape_L = Tape_N()

  cur_Tape_L *= Cable_L()

  cur_Tape_L

end