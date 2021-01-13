/** @noSelfInFile */

type BuilderAvailableType = void|string|number
type BuilderDataTemplate<T extends BuilderAvailableType> = T | Array<BuilderDataTemplate<T>>;
type BuilderData = BuilderDataTemplate<BuilderAvailableType>

type BuilderFunc<T extends BuilderData> = (...args: BuilderData[]) => T

declare function IsGame(): boolean;
declare function GetSrc(): (string|null);
declare function GetDst(): (string|null);

declare function Macro<T extends BuilderData>(val: T) : T;
declare function Macro<T extends BuilderData>(func: BuilderFunc<T>, ...args: BuilderData[]) : T;
declare function BuildFinal<T extends BuilderData>(func: BuilderFunc<T>, ...args: BuilderData[]) : T;