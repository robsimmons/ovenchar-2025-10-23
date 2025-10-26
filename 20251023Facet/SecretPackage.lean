import Lean
open Lean

abbrev Key := UInt64

structure SecretPackage a where
  func : (String → a)
  file : Option String
  key : Key

def SecretPackage.read : SecretPackage a -> IO a
  | .mk func file key => do
    let .some file := file
      | throw <| .userError "Secrets cannot be read in the file where they are defined when using the language server protocol"
    let keyStr := ToString.toString key ++ ":"
    let file := ((← IO.currentDir) / ".secrets" / s!"{file}.txt")
    for line in ← IO.FS.lines file do
      if line.startsWith keyStr then
        match Json.parse (line.drop keyStr.length |>.trim) with
        | .error msg => throw <| .userError msg
        | .ok json => match json.getStr? with
          | .error msg => throw <| .userError msg
          | .ok str => return (func str)
    throw <| .userError s!"File {file} did not contain key {key}"
