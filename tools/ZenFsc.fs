// Compiles with Zen.FSharp.Compiler.Service (the patched F# compiler that build.fsx and the node's contract tool
// use; it accepts the type abbreviations F* extraction produces). Arguments: the same as fsc.exe.
module ZenFsc
open Microsoft.FSharp.Compiler.SourceCodeServices

[<EntryPoint>]
let main argv =
    let checker = FSharpChecker.Create()
    let messages, exitCode = checker.Compile(Array.append [| "fsc.exe" |] argv) |> Async.RunSynchronously
    for m in messages do
        if m.Severity = FSharpErrorSeverity.Error then eprintfn "error %s(%d,%d): %s" m.FileName m.StartLineAlternate m.StartColumn m.Message
    exitCode
