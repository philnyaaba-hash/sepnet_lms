export const cloudinaryConfig = {
  cloudName: "dwsl2ktt2",
  secure: true,
  thumbnailOffset: 3,
};

export function getVideoThumbnail(
  cloudinaryId: string,
  offset: number = cloudinaryConfig.thumbnailOffset
): string {
  return `https://res.cloudinary.com/${cloudinaryConfig.cloudName}/video/upload/so_${offset}/w_800,h_450,c_fill,q_auto,f_auto/${cloudinaryId}.jpg`;
}
