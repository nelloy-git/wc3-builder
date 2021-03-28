/** @noSelfInFile */

type BuildtimeTable = LuaTable<number | string, BuildtimeData>
type BuildtimeData = undefined | boolean | number | string | BuildtimeTable
type BuilderFunc<T extends BuildtimeData> = (...args: BuildtimeData[]) => T | void

declare function IsGame(): boolean;
declare function GetSrc(): string | undefined;
declare function GetDst(): string | undefined;
declare function getLoadingPackage(depth?: number): string | undefined

declare function Macro<T extends BuildtimeData>(val: T) : T;
declare function Macro<T extends BuildtimeData>(func: BuilderFunc<T>, ...args: BuildtimeData[]) : T;
declare function MacroFinal<T extends BuildtimeData>(func: BuilderFunc<T>, ...args: BuildtimeData[]) : T;