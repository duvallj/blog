/* eslint-disable */
/// <reference path="../.astro/types.d.ts" />
/// <reference types="astro/client" />

// Fill in types for capitalized versions of files
declare module "*.JPG" {
  export default import("astro").ImageMetadata;
}
declare module "*.PNG" {
  export default import("astro").ImageMetadata;
}
