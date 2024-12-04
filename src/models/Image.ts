export type Image = {
  /**
   * Filename for the image. MUST be relative to https://static.duvallj.pw/photography/<dir>/
   */
  imgfile: string;
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
  eager?: true;
  /**
   * Maximum width of the rendered image (in px)
   */
  maxWidth?: number;
  /**
   * Maximum height of the rendered image (in px)
   */
  maxHeight?: number;
  /**
   * If provided, allows an image to scroll in the X direction instead of being scaled down.
   */
  scrollX?: true;
  /**
   * If provided, scales the image down in the Y direction by forcing it to have more margin, so that it doesn't appear so tall
   */
  marginY?: string;
};
