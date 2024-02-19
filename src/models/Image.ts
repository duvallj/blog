import type { ImageMetadata } from "astro";

export type Image = {
  /**
   * Filename for the image. Use `await import` for this.
   */
  imgfile: ImageMetadata;
  /**
   * title component for the image (text that shows up on hover)
   */
  imgtitle?: string;
  /**
   * alt component for the image (text for screenreaders)
   */
  imgalt?: string;
  /**
   * Image caption (below the image)
   */
  caption: string;
  /**
   * Image title (above the image)
   */
  title: string;
  /**
   * Whether this above-the-fold image should be eagerly loaded
   */
  eager?: boolean;
};
