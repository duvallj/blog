import type { Image } from "./Image";

export type ImageListProps = {
  /**
   * Root path for the image filenames. Must not end with a "/"
   */
  imgroot: string;
  images: Image[];
};
