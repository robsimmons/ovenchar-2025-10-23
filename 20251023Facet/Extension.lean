import Lean
import Std
import «20251023Facet».SecretPackage

open Lean Std

initialize secretPlaceholderExt : EnvExtension (Option Expr) ← registerEnvExtension (pure .none)
initialize redactedStringExt : EnvExtension (Option String) ← registerEnvExtension (pure .none)
initialize newFileExt : EnvExtension Bool ← registerEnvExtension (pure true)

elab "__REDACTED " s:str "__" : term => do
  let env ← getEnv
  if let .some secret := secretPlaceholderExt.getState env then
    if let .some _ := redactedStringExt.getState env then
      throwError "The `__REDACTED <str> __` syntax appears more than once within this `secretive` definition."
    else
      modifyEnv (redactedStringExt.setState · (.some s.getString))
      return secret
  else
    throwError "The `__REDACTED <str> __` syntax can only be used within a `secretive` definition."

def storeSecret (key: Key) (str : String) : CoreM String := do
  let cwd := (← IO.currentDir).components.toArray
  let ctx ← readThe Core.Context
  let currFile : System.FilePath := System.FilePath.mk ctx.fileName
  let .some stem := currFile.fileStem
    | throwError s!"Current lean filename `{ctx.fileName}` seems ill-formed"
  let .some currDir := currFile.parent
      |>.map (·.components)
      |>.map (·.toArray)
    | throwError s!"Current lean filename `{ctx.fileName}` seems ill-formed"

  if currDir.size < cwd.size || currDir.take cwd.size != cwd then
    throwError s!"File `{ctx.fileName}` cannot be compiled outside of directory `{← IO.currentDir}`"

  let secretStem := currDir.drop cwd.size |>.push stem |>.toList |> ".".intercalate
  let secretDir := (← IO.currentDir) / ".secrets"
  let secretFile := secretDir / (secretStem ++ ".txt")

  IO.FS.createDirAll secretDir
  let mode : IO.FS.Mode := if newFileExt.getState (← getEnv) then .write else .append
  let file ← IO.FS.Handle.mk secretFile mode
  file.write s!"{key}:{(ToJson.toJson str).compress}\n".toUTF8
  file.flush

  modifyEnv (newFileExt.setState · false)
  pure secretStem

elab "secretive" name:ident ":=" tm:term : command => do
  try
    let implName ← Elab.Command.runTermElabM fun _ => do
      let implName ← mkFreshUserName `secretive_impl
      let secretPlaceholder ← Meta.mkFreshExprMVar (mkConst ``String)
      modifyEnv (secretPlaceholderExt.setState · (.some secretPlaceholder))
      modifyEnv (redactedStringExt.setState · .none)

      let e ← Elab.Term.elabTerm tm none
      let t ← Meta.inferType e
      let env ← getEnv
      if let .some secretStr := redactedStringExt.getState env then
        let hash := Hashable.hash secretStr
        let path ← storeSecret hash secretStr

        -- let absT ← Meta.mkForallFVars #[secretPlaceholder] t
        let absE ← Meta.mkLambdaFVars #[secretPlaceholder] e
        let packageT ← Meta.mkAppM ``SecretPackage #[t]
        let packageE ← Meta.mkAppM ``SecretPackage.mk #[absE, ToExpr.toExpr path, ToExpr.toExpr hash]
        Elab.Term.synthesizeSyntheticMVarsNoPostponing
        addAndCompile <| .defnDecl {
          name := implName,
          levelParams := [],
          type := ← instantiateMVars packageT,
          value := ← instantiateMVars packageE,
          hints := .abbrev
          safety := .safe
        }
        return implName
      else
        throwErrorAt name "Secretive definition did not include a `__REDACTED <str> __`"

    Elab.Command.elabCommand (← `(def $name := $(mkIdent implName)))

  finally
    modifyEnv (secretPlaceholderExt.setState · .none)
    modifyEnv (redactedStringExt.setState · .none)
