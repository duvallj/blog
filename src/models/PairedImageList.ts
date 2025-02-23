import type { ImageDetails, ImageWithoutDetails } from "./Image";

export interface PairedImageDetails extends ImageDetails {
  /**
   * How the image pairs should be laid out. Default: "row"
   */
  layout: "row" | "col" | undefined;
}

export interface PairedImages {
  images: ImageWithoutDetails[];
  details: PairedImageDetails;
}

export interface PairedImageListProps {
  pairedImages: PairedImages[];
  // MUST be relative to https://static.duvallj.pw/photography
  dir: string;
}
