type PresenceMetadata = {online_at?: string; phx_ref: string};

export type PhoenixPresence = {
  [key: string]: {
    metas: Array<PresenceMetadata>;
  } | null;
};

export type PresenceDiff = {
  joins: PhoenixPresence;
  leaves: PhoenixPresence;
};

export const updatePresenceWithDiff = (
  presence: PhoenixPresence,
  diff: PresenceDiff
) => {
  const {joins, leaves} = diff;

  const withJoins = updatePresenceWithJoiners(joins, presence);
  const withLeaves = updatePresenceWithExiters(leaves, presence);
  const combined = {...withJoins, ...withLeaves};
  const latest = Object.keys(combined).reduce((acc, key: string) => {
    if (!combined[key]) {
      return acc;
    }

    return {...acc, [key]: combined[key]};
  }, {} as PhoenixPresence);

  return latest;
};

const updatePresenceWithJoiners = (
  joiners: PhoenixPresence,
  currentState: PhoenixPresence
): PhoenixPresence => {
  // Update our presence state by adding all the joiners, represented by
  // keys like "customer:1a2b3c", "user:123", etc.
  // The `metas` represent the metadata of each presence. A single user/customer
  // can have multiple `metas` if logged into multiple devices/windows.
  let result = {...currentState};

  Object.keys(joiners).forEach((key) => {
    const existing = result[key];
    const update = joiners[key];

    // `metas` is how Phoenix tracks each individual presence
    if (!update || !update.metas) {
      throw new Error(`Unexpected join state: ${update}`);
    }

    if (existing && existing.metas) {
      result[key] = {metas: [...existing.metas, ...update.metas]};
    } else {
      result[key] = {metas: update.metas};
    }
  });

  return result;
};

const updatePresenceWithExiters = (
  exiters: PhoenixPresence,
  currentState: PhoenixPresence
): PhoenixPresence => {
  // Update our presence state by removing all the exiters, represented by
  // keys like "customer:1a2b3c", "user:123", etc. We currently indicate an
  // "exit" by setting their key to `null`.
  // The `metas` represent the metadata of each presence. A single user/customer
  // can have multiple `metas` if logged into multiple devices/windows.
  let result = {...currentState};

  Object.keys(exiters).forEach((key) => {
    const existing = result[key];
    const update = exiters[key];

    // `metas` is how Phoenix tracks each individual presence
    if (!update || !update.metas) {
      throw new Error(`Unexpected leave state: ${update}`);
    }

    if (existing && existing.metas) {
      const remaining = existing.metas.filter((meta: PresenceMetadata) => {
        return update.metas.some(
          (m: PresenceMetadata) => meta.phx_ref !== m.phx_ref
        );
      });

      result[key] = remaining.length ? {metas: remaining} : null;
    } else {
      result[key] = null;
    }
  });

  return result;
};
