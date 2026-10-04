import { Illustration, TINT_HEX } from "@/components/illustrations/Illustration";
import { Tape } from "@/components/ui/misc";
import { cn } from "@/lib/cn";
import type { PhotoProof } from "@/lib/types";

/** Placeholder photo proof: an illustrated "snapshot" in a taped polaroid frame. */
export function Polaroid({ photo, size = 120, rotate = -3, className, tape = true }: { photo: PhotoProof; size?: number; rotate?: number; className?: string; tape?: boolean }) {
  const tint = TINT_HEX[photo.tint];
  return (
    <figure
      className={cn("relative inline-block shrink-0 bg-[#fffaf0] p-1.5 pb-0 shadow-[0_1px_0_rgb(0_0_0/0.06),0_8px_16px_-8px_rgb(70_30_20/0.45)]", className)}
      style={{ width: size, transform: `rotate(${rotate}deg)` }}
    >
      {tape && <Tape className="-top-2 left-1/2 -ml-[27px]" rotate={rotate > 0 ? -4 : 5} />}
      <div
        className="relative grid aspect-square w-full place-items-center overflow-hidden"
        style={{ background: `radial-gradient(circle at 30% 25%, #fffaf0 0, ${tint}55 45%, ${tint} 100%)` }}
        role="img"
        aria-label={`Photo proof: ${photo.caption}`}
      >
        <span className="absolute inset-x-0 bottom-0 h-1/3" style={{ background: `${tint}` , opacity: 0.35 }} aria-hidden />
        <Illustration kind={photo.motif} size={size * 0.5} />
      </div>
      <figcaption className="truncate px-0.5 py-1 text-center font-hand text-[0.95rem] leading-tight text-[#3a2a28]" style={{ fontSize: Math.max(13, size * 0.12) }}>
        {photo.caption}
      </figcaption>
    </figure>
  );
}
