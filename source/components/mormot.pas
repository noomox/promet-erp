{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit mormot;

interface

uses
  SynSQLite3, LazarusPackageIntf;

implementation

procedure Register;
begin
end;

initialization
  RegisterPackage('mormot', @Register);
end.
