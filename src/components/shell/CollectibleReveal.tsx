"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";
import { CollectibleDetail } from "@/components/collection/CollectibleDetail";
import { BottomSheet } from "@/components/ui/BottomSheet";
import { Button } from "@/components/ui/Button";
import { useAppState, useDispatch } from "@/lib/store/provider";

/** Global celebratory sheet shown when an action unlocks a new collectible. */
export function CollectibleReveal() {
  const { pendingReveal, session } = useAppState();
  const dispatch = useDispatch();
  const router = useRouter();
  const open = Boolean(pendingReveal) && session.onboarded;
  // Keep the last id so the sheet's content stays put while it animates closed.
  const [shown, setShown] = useState(pendingReveal);
  if (pendingReveal && pendingReveal !== shown) setShown(pendingReveal);
  const close = () => dispatch({ type: "reveal/dismiss" });
  return (
    <BottomSheet
      open={open}
      onClose={close}
      title="New sticker!"
      description="Peeled fresh and added to your Collection."
      footer={
        <div className="flex gap-2">
          <Button
            variant="secondary"
            block
            onClick={() => {
              close();
              router.push("/collection");
            }}
          >
            Open collection
          </Button>
          <Button block onClick={close} data-autofocus>
            Lovely
          </Button>
        </div>
      }
    >
      {shown && <CollectibleDetail id={shown} reveal />}
    </BottomSheet>
  );
}
