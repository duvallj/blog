import type { Image } from "./Image";

export interface ImageListProps {
  images: Image[];
  // MUST be relative to https://static.duvallj.pw/photography
  dir: string;
}
