{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit pSheme;

{$warn 5023 off : no warning about unused units}
interface

uses
  uschemeframe, uSchemenodeproperties, uschemelinkproperties, 
  LazarusPackageIntf;

implementation

procedure Register;
begin
end;

initialization
  RegisterPackage('pSheme', @Register);
end.
