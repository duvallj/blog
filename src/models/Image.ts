export interface Image {
  /**
   * Filename for the image. Styled like "01.png"
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
}
