import Lake

open System Lake DSL

package «2025-10-23-facet» where version := v!"0.1.0"

lean_lib «20251023Facet»

@[default_target] lean_exe «2025-10-23-facet» where root := `Main

/-
@[default_target] lean_exe goof where root := `Goof

module_facet bwddwb mod : System.FilePath := do
  let ws ← getWorkspace

  let modJob : Job FilePath ← mod.olean.fetch

  let buildDir := ws.root.buildDir
  let litFile := mod.filePath (buildDir / "thingy") "txt"

  modJob.mapM fun _oleanPath => do
    addLeanTrace
    buildFileUnlessUpToDate' (text := true) litFile <| do
      IO.FS.createDirAll (buildDir / "thingy" / mod.relLeanFile)
      IO.FS.writeFile litFile s!"I captured {mod.leanFile}"
    pure litFile

  -- make an environment extension where for any given module creates the json I want to save (the deduplication table now)
  -- command line tool invokes the lean frontend as a library, loads the module that it's passed as an argument or elaborates it from scratch and extracts the contents of that environment extension and saves it to a disk
  -- take the olean as a command line parameter and output file as the command line parameter
  -- line 19 already has the olean path, modjob
  -- lake ensures I have an olean and

  -- What does my executable do — it calls lake query with the facet (lake query 20251023Facet:thingy), this gives path to the generated json file, each json says where it comes from, and then populate a hashtable that's then the result of elaborating a document is a function that needs that hashtable

library_facet thingy2 lib : Array System.FilePath := do
  let mods ← (← lib.modules.fetch).await
  let lits ← mods.mapM fun x =>
    x.facet `bwddwb |>.fetch
  pure <| Job.collectArray lits
-/
