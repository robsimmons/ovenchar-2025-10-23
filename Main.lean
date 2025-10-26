import «20251023Facet»

def main : IO Unit := do
  IO.println s!"x: {← x.read}!"
  IO.println s!"y: {← y.read}!"
  IO.println s!"xx: {← xx.read}!"
  IO.println s!"yy: {← yy.read}!"
