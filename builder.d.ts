/** @noSelfInFile */

type BuilderData = string|number|undefined|(string|number|undefined)[]
type BuilderFunc = (...args: BuilderData[]) => BuilderData

declare function IsGame() : boolean;
declare function GetSrc() : (string|null);
declare function GetDst() : (string|null);
declare function Macro(val : BuilderData) : BuilderData;
declare function Macro(func: BuilderFunc, ...args: BuilderData[]) : BuilderData;
declare function BuildFinal(func: BuilderFunc, ...args: BuilderData[]) : BuilderData;