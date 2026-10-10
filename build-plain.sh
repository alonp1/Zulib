#!/bin/bash
# Builds bin/Zulib.dll without FAKE (FAKE 4 no longer runs on current Mono): the same F* extraction and the
# same compile inputs as build.fsx (targets Extract and Build).
set -euo pipefail
chmod +x packages/zen_z3_linux/output/z3-linux
EXTRACT=(Zen.Integers Zen.Base Zen.Result Zen.ResultT Zen.Option Zen.OptionT Zen.Optics Zen.Array.Indexed Zen.Cost.Extracted Zen.List
         Zen.Types.Extracted Zen.Types.Data Zen.Types.Main Zen.PublicKey Zen.Sha3.Extracted Zen.Hash.Base Zen.Data Zen.ContractReturn Zen.ContractResult)
ARGS=(--lax --codegen FSharp)
for m in "${EXTRACT[@]}"; do ARGS+=(--extract_module "$m"); done
ARGS+=(--codegen-lib Zen.Cost --codegen-lib Zen.Array --codegen-lib Zen.Types --codegen-lib Zen.Sha3 --codegen-lib Zen.Hash --odir fsharp/Extracted)
mkdir -p fsharp/Extracted bin
mono packages/ZFStar/tools/fstar.exe --smt packages/zen_z3_linux/output/z3-linux --prims "$PWD/fstar/prims.fst" \
  --no_default_includes --include fstar/ "${ARGS[@]}" "$PWD"/fstar/*.fst "$PWD"/fstar/*.fsti
ls fsharp/Extracted
FILES=$(sed -n '/^Target "Build"/,/|\]/p' build.fsx | grep -v '^ *//' | grep -o '"fsharp/[^"]*\.fs"' | grep -v '^//' | tr -d '"')
FW=/usr/lib/mono/4.7-api
pick() { ls $1 2>/dev/null | head -n 1; }
FSCORE=$(pick "packages/FSharp.Core/lib/net45/FSharp.Core.dll"); OCAML=$(pick "packages/FSharp.Compatibility.OCaml/lib/net45/FSharp.Compatibility.OCaml.dll")
FSX=$(pick "packages/FSharpx.Collections/lib/net4*/FSharpx.Collections.dll"); BC=$(pick "packages/BouncyCastle/lib/BouncyCastle.Crypto.dll"); B32=$(pick "packages/FsBech32/lib/net4*/FsBech32.dll")
echo "refs: $FSCORE $OCAML $FSX $BC $B32"
# the compiler runner: Zen.FSharp.Compiler.Service and the System.Reflection.Metadata 1.4.1 it needs (as build.sh does for FAKE)
mkdir -p tools/bin
FCS=$(ls packages/Zen.FSharp.Compiler.Service/lib/net45/Zen.FSharp.Compiler.Service.dll)
cp "$FCS" tools/bin/; cp Zen.FSharp.Compiler.Service.dll.config tools/bin/
cp packages/metadatafix/System.Reflection.Metadata/lib/portable-net45+win8/System.Reflection.Metadata.dll tools/bin/
IMM=$(ls packages/System.Collections.Immutable/lib/*/System.Collections.Immutable.dll 2>/dev/null | head -n 1 || true); [ -n "$IMM" ] && cp "$IMM" tools/bin/
cp "$FSCORE" tools/bin/
fsharpc --nologo -o tools/bin/zenfsc.exe -r tools/bin/Zen.FSharp.Compiler.Service.dll -r tools/bin/FSharp.Core.dll --noframework \
  -r $FW/mscorlib.dll -r $FW/System.dll -r $FW/System.Core.dll -r $FW/System.Runtime.dll -r $FW/Facades/System.Runtime.dll tools/ZenFsc.fs 2>&1 || \
fsharpc --nologo -o tools/bin/zenfsc.exe -r tools/bin/Zen.FSharp.Compiler.Service.dll tools/ZenFsc.fs
ls tools/bin
mono tools/bin/zenfsc.exe -o bin/Zulib.dll -a --noframework -r $FW/mscorlib.dll -r $FW/System.Core.dll -r $FW/System.dll -r $FW/System.Numerics.dll \
  -r "$FSCORE" -r "$OCAML" -r "$FSX" -r "$BC" -r "$B32" $FILES
ls -la bin
