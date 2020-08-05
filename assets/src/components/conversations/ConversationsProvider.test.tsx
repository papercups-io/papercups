import {
  updatePresenceWithJoiners,
  updatePresenceWithExiters,
} from './ConversationsProvider';

const getTestPresenceState = () => {
  return {
    'user:1': {metas: [{phx_ref: '1u'}]},
    'customer:2': {metas: [{phx_ref: '2c'}]},
    'user:3': {metas: [{phx_ref: '3u'}]},
    'customer:4': {metas: [{phx_ref: '4c'}]},
  };
};

describe('updatePresenceWithJoiners', () => {
  test('with brand new presence', () => {
    const unseen = 'customer:10';
    const joiners = {
      [unseen]: {metas: [{phx_ref: 'unseen'}]},
    };
    const presence = getTestPresenceState();
    const update = updatePresenceWithJoiners(joiners, presence);

    expect(update[unseen]?.metas).toEqual([{phx_ref: 'unseen'}]);
  });

  test('with additional presence for existing customer', () => {
    const existing = 'customer:2';
    const joiners = {
      [existing]: {metas: [{phx_ref: 'another'}]},
    };
    const presence = getTestPresenceState();
    const update = updatePresenceWithJoiners(joiners, presence);

    expect(update[existing]?.metas).toEqual([
      {phx_ref: '2c'},
      {phx_ref: 'another'},
    ]);
  });

  test('with a combination of new and additional presences', () => {
    const existing = 'customer:2';
    const unseen = 'customer:10';
    const joiners = {
      [existing]: {metas: [{phx_ref: 'another'}]},
      [unseen]: {metas: [{phx_ref: 'unseen'}]},
    };
    const presence = getTestPresenceState();
    const update = updatePresenceWithJoiners(joiners, presence);

    expect(update[existing]?.metas).toEqual([
      {phx_ref: '2c'},
      {phx_ref: 'another'},
    ]);
    expect(update[unseen]?.metas).toEqual([{phx_ref: 'unseen'}]);
  });
});

describe('updatePresenceWithExiters', () => {
  test('removes the key completely if only one presence exists', () => {
    const key = 'customer:2';
    const exiters = {
      [key]: {metas: [{phx_ref: '2c'}]},
    };
    const presence = getTestPresenceState();
    const update = updatePresenceWithExiters(exiters, presence);

    expect(update[key]).toBeNull();
  });

  test('removes the metadata if multiple presences exist', () => {
    const key = 'customer:1';
    const joiners = {
      [key]: {metas: [{phx_ref: 'another'}]},
    };
    const presence = {
      [key]: {metas: [{phx_ref: 'first'}, {phx_ref: 'another'}]},
    };
    const update = updatePresenceWithExiters(joiners, presence);

    expect(update[key]?.metas).toEqual([{phx_ref: 'first'}]);
  });

  test('does nothing if no presence exists already', () => {
    const key = 'customer:1';
    const joiners = {
      [key]: {metas: [{phx_ref: 'first'}]},
    };
    const presence = {};
    const update = updatePresenceWithExiters(joiners, presence);

    expect(update[key]).toBeNull();
  });
});
