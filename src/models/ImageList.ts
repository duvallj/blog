import type { Image } from "./Image";

export interface ImageListProps {
  /**
   * Root path for the image filenames. Must not end with a "/"
   */
  imgroot: string;
  images: Image[];
}
