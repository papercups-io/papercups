import React from 'react';
import {Box, Flex} from 'theme-ui';
import {Button, Select, Tag, Text} from '../common';
import Spinner from '../Spinner';
import * as API from '../../api';
import * as T from '../../types';
import logger from '../../logger';

type TagOption = {
  id?: string;
  label: string;
  value: string;
};

const getTagDiff = (current: Array<T.Tag>, next: Array<TagOption>) => {
  const currentIds = current.map((t) => t.id);
  const remainingIds = next.filter((t) => !!t.id).map((t) => t.id as string);

  return {
    // new tags without an id need to be created
    create: next.filter((t) => !t.id).map((t) => t.value),
    // new tags that don't appear in the current list need to be added
    add: remainingIds.filter((tagId) => currentIds.indexOf(tagId) === -1),
    // if tags from the current state are missing from the next state, remove them
    remove: currentIds.filter(
      (tagId: string) => remainingIds.indexOf(tagId) === -1
    ),
  };
};

type State = {
  loading: boolean;
  editing: boolean;
  updating: boolean;
  current: Array<T.Tag>;
  updated: Array<TagOption>;
  options: Array<T.Tag>;
};

const initial: State = {
  loading: false,
  editing: false,
  updating: false,
  current: [],
  updated: [],
  options: [],
};

type Action = {
  type:
    | 'loading/start'
    | 'loading/stop'
    | 'editing/start'
    | 'updating/start'
    | 'updating/done'
    | 'tags/init'
    | 'tags/update';
  payload?: any;
};

const reducer = (state: State, action: Action) => {
  const {type, payload} = action;

  switch (type) {
    case 'loading/start':
      return {...state, loading: true};
    case 'loading/stop':
      return {...state, loading: false};
    case 'editing/start':
      return {...state, editing: true};
    case 'updating/start':
      return {...state, updating: true};
    case 'updating/done':
      return {...state, updating: false, editing: false};
    case 'tags/init':
      return {
        ...state,
        current: payload.current,
        updated: payload.updated,
        options: payload.options,
      };
    case 'tags/update':
      return {...state, updated: payload};
    default:
      return state;
  }
};

// TODO: find a way to clean this up a bit...
// Maybe experiment with `useReducer`, or just avoid using hooks in general?
export const SidebarCustomerTags = ({customerId}: {customerId: string}) => {
  const [state, dispatch] = React.useReducer(reducer, initial);

  React.useEffect(() => {
    dispatch({type: 'loading/start'});

    refreshLatestTags().then(() => dispatch({type: 'loading/stop'}));
    // eslint-disable-next-line
  }, [customerId]);

  function handleStartEditing() {
    dispatch({type: 'editing/start'});
  }

  async function refreshLatestTags() {
    return Promise.all([API.fetchCustomer(customerId), API.fetchAllTags()])
      .then(([customer, tags]) => {
        dispatch({
          type: 'tags/init',
          payload: {
            current: customer.tags,
            updated: customer.tags.map((tag: T.Tag) => {
              return {id: tag.id, label: tag.name, value: tag.name};
            }),
            options: tags,
          },
        });
      })
      .catch((err) => {
        logger.error('Failed to fetch customer details:', err);
      });
  }

  function handleChangeTags(values: Array<string>, tags: any) {
    const updated = tags.map((t: TagOption, idx: number) => {
      const value = values[idx];

      return {...t, value, label: value};
    });

    dispatch({type: 'tags/update', payload: updated});
  }

  function handleUpdateTags() {
    dispatch({type: 'updating/start'});

    const {current = [], updated = []} = state;
    const {
      create: newTagsToCreate,
      add: tagIdsToAdd,
      remove: tagIdsToRemove,
    } = getTagDiff(current, updated);

    const promises = [
      ...newTagsToCreate.map((name: string) =>
        API.createTag(name).then(({id: tagId}) =>
          API.addCustomerTag(customerId, tagId)
        )
      ),
      ...tagIdsToAdd.map((tagId: string) =>
        API.addCustomerTag(customerId, tagId)
      ),
      ...tagIdsToRemove.map((tagId: string) =>
        API.removeCustomerTag(customerId, tagId)
      ),
    ];

    Promise.all(promises)
      .then((results) => {
        logger.debug('Successfully updated customer tags:', results);
      })
      .catch((err) => {
        logger.error('Failed to update customer tags:', err);
      })
      .then(() => refreshLatestTags())
      .then(() => dispatch({type: 'updating/done'}));
  }

  if (state.loading) {
    return <Spinner size={16} />;
  }

  return (
    <Box>
      <Box mb={1}>
        {/* TODO: figure out a nicer design for this */}
        {state.editing ? (
          <Select
            mode="tags"
            style={{width: '100%'}}
            placeholder="Add tags"
            value={state.updated.map((t: TagOption) => t.value)}
            onChange={handleChangeTags}
            options={state.options.map((tag: T.Tag) => {
              const {id, name} = tag;

              return {id, key: id, label: name, value: name};
            })}
          />
        ) : (
          <Flex sx={{flexWrap: 'wrap'}}>
            {state.current && state.current.length ? (
              state.current.map((tag: T.Tag, idx: number) => {
                const options = ['magenta', 'red', 'volcano', 'purple', 'blue'];
                const color = options[idx % 5];
                const {id, name} = tag;

                return (
                  <Box key={id} my={1}>
                    <Tag key={id} color={color}>
                      {name}
                    </Tag>
                  </Box>
                );
              })
            ) : (
              <Text type="secondary">None</Text>
            )}
          </Flex>
        )}
      </Box>
      <Box mb={1}>
        {state.editing ? (
          <Button
            size="small"
            type="primary"
            loading={state.updating}
            onClick={handleUpdateTags}
          >
            Done
          </Button>
        ) : (
          <Button
            size="small"
            loading={state.updating}
            onClick={handleStartEditing}
          >
            {state.current && state.current.length ? 'Edit' : 'Add'}
          </Button>
        )}
      </Box>
    </Box>
  );
};

export const SidebarConversationTags = ({
  conversationId,
}: {
  conversationId: string;
}) => {
  const [state, dispatch] = React.useReducer(reducer, initial);

  React.useEffect(() => {
    dispatch({type: 'loading/start'});

    refreshLatestTags().then(() => dispatch({type: 'loading/stop'}));
    // eslint-disable-next-line
  }, [conversationId]);

  function handleStartEditing() {
    dispatch({type: 'editing/start'});
  }

  async function refreshLatestTags() {
    return Promise.all([
      API.fetchConversation(conversationId),
      API.fetchAllTags(),
    ])
      .then(([conversation, tags]) => {
        const {tags: conversationTags = []} = conversation;

        dispatch({
          type: 'tags/init',
          payload: {
            current: conversationTags,
            updated: conversationTags.map((tag: T.Tag) => {
              return {id: tag.id, label: tag.name, value: tag.name};
            }),
            options: tags,
          },
        });
      })
      .catch((err) => {
        logger.error('Failed to fetch customer details:', err);
      });
  }

  function handleChangeTags(values: Array<string>, tags: any) {
    const updated = tags.map((t: TagOption, idx: number) => {
      const value = values[idx];

      return {...t, value, label: value};
    });

    dispatch({type: 'tags/update', payload: updated});
  }

  function handleUpdateTags() {
    dispatch({type: 'updating/start'});

    const {current = [], updated = []} = state;
    const {
      create: newTagsToCreate,
      add: tagIdsToAdd,
      remove: tagIdsToRemove,
    } = getTagDiff(current, updated);

    const promises = [
      ...newTagsToCreate.map((name: string) =>
        API.createTag(name).then(({id: tagId}) =>
          API.addConversationTag(conversationId, tagId)
        )
      ),
      ...tagIdsToAdd.map((tagId: string) =>
        API.addConversationTag(conversationId, tagId)
      ),
      ...tagIdsToRemove.map((tagId: string) =>
        API.removeConversationTag(conversationId, tagId)
      ),
    ];

    Promise.all(promises)
      .then((results) => {
        logger.debug('Successfully updated conversation tags:', results);
      })
      .catch((err) => {
        logger.error('Failed to update conversation tags:', err);
      })
      .then(() => refreshLatestTags())
      .then(() => dispatch({type: 'updating/done'}));
  }

  if (state.loading) {
    return <Spinner size={16} />;
  }

  return (
    <Box>
      <Box mb={1}>
        {/* TODO: figure out a nicer design for this */}
        {state.editing ? (
          <Select
            mode="tags"
            style={{width: '100%'}}
            placeholder="Add tags"
            value={state.updated.map((t: TagOption) => t.value)}
            onChange={handleChangeTags}
            options={state.options.map((tag: T.Tag) => {
              const {id, name} = tag;

              return {id, key: id, label: name, value: name};
            })}
          />
        ) : (
          <Flex sx={{flexWrap: 'wrap'}}>
            {state.current && state.current.length ? (
              state.current.map((tag: T.Tag, idx: number) => {
                const options = ['magenta', 'red', 'volcano', 'purple', 'blue'];
                const color = options[idx % 5];
                const {id, name} = tag;

                return (
                  <Box key={id} my={1}>
                    <Tag key={id} color={color}>
                      {name}
                    </Tag>
                  </Box>
                );
              })
            ) : (
              <Text type="secondary">None</Text>
            )}
          </Flex>
        )}
      </Box>
      <Box mb={1}>
        {state.editing ? (
          <Button
            size="small"
            type="primary"
            loading={state.updating}
            onClick={handleUpdateTags}
          >
            Done
          </Button>
        ) : (
          <Button
            size="small"
            loading={state.updating}
            onClick={handleStartEditing}
          >
            {state.current && state.current.length ? 'Edit' : 'Add'}
          </Button>
        )}
      </Box>
    </Box>
  );
};
