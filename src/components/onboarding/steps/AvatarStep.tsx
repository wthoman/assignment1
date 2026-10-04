"use client";

import { useState } from "react";
import { Button } from "@/components/ui/Button";
import { useDispatch, useMe } from "@/lib/store/provider";
import { AvatarCustomizer } from "../AvatarCustomizer";
import { StepShell } from "../StepShell";

export function AvatarStep({ onNext, reduce }: { onNext: () => void; reduce: boolean }) {
  const dispatch = useDispatch();
  const me = useMe();
  const [config, setConfig] = useState(me.avatar);

  const submit = () => {
    dispatch({ type: "profile/avatar", patch: config });
    onNext();
  };

  return (
    <StepShell
      eyebrow="Your avatar"
      title="Draw yourself in"
      description="Friends see this next to your check-ins. Change it any time."
      onSubmit={submit}
      footer={
        <Button type="submit" size="lg" block>
          Looks like me
        </Button>
      }
    >
      <AvatarCustomizer value={config} onChange={setConfig} reduce={reduce} />
    </StepShell>
  );
}
