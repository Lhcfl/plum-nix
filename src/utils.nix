# To use it, pass nixpkgs.lib into it.
lib:
let
  run = lib.flip lib.pipe;

  encode = tag: data: {
    __PLUM_PATCH_TAG = tag;
    __PLUM_PATCH_DATA = data;
  };
  tag = { __PLUM_PATCH_TAG, ... }: __PLUM_PATCH_TAG;
  data = { __PLUM_PATCH_DATA, ... }: __PLUM_PATCH_DATA;

  hasNoTag = x: !(lib.attrsets.hasAttr "__PLUM_PATCH_TAG" x);

  replace = encode "=";
  append = encode "+";

  joinPath = path: tag: lib.concatStringsSep "/" (path ++ [ tag ]);

  mkPatch = run [
    (lib.mapAttrsToListRecursiveCond (_: hasNoTag) (
      path: x: {
        name = joinPath path (tag x);
        value = data x;
      }
    ))
    lib.attrsets.listToAttrs
  ];
in
{
  inherit
    replace
    append
    mkPatch
    ;
}
