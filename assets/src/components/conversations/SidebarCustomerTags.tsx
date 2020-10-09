import React from 'react';
import {Box, Flex} from 'theme-ui';
import {Button, Select, Tag, Text} from '../common';
import Spinner from '../Spinner';
import * as API from '../../api';
import logger from '../../logger';

type State = {
  loading: boolean;
  editing: boolean;
  updating: boolean;
  current: Array<any>;
  updated: Array<any>;
  options: Array<any>;
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
    | 'loading:start'
    | 'loading:stop'
    | 'editing:start'
    | 'updating:start'
    | 'updating:done'
    | 'tags:init'
    | 'tags:update';
  payload?: any;
};

const reducer = (state: State, action: Action) => {
  const {type, payload} = action;

  switch (type) {
    case 'loading:start':
      return {...state, loading: true};
    case 'loading:stop':
      return {...state, loading: false};
    case 'editing:start':
      return {...state, editing: true};
    case 'updating:start':
      return {...state, updating: true};
    case 'updating:done':
      return {...state, updating: false, editing: false};
    case 'tags:init':
      return {
        ...state,
        current: payload.current,
        updated: payload.updated,
        options: payload.options,
      };
    case 'tags:update':
      return {...state, updated: payload};
    default:
      return state;
  }
};

// TODO: find a way to clean this up a bit...
// Maybe experiment with `useReducer`, or just avoid using hooks in general?
const SidebarCustomerTags = ({customerId}: {customerId: string}) => {
  const [state, dispatch] = React.useReducer(reducer, initial);

  React.useEffect(() => {
    dispatch({type: 'loading:start'});

    refreshLatestTags().then(() => dispatch({type: 'loading:stop'}));
    // eslint-disable-next-line
  }, [customerId]);

  function handleStartEditing() {
    dispatch({type: 'editing:start'});
  }

  async function refreshLatestTags() {
    return Promise.all([API.fetchCustomer(customerId), API.fetchAllTags()])
      .then(([customer, tags]) => {
        dispatch({
          type: 'tags:init',
          payload: {
            current: customer.tags,
            updated: customer.tags.map((tag: any) => {
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
    const updated = tags.map((t: any, idx: number) => {
      const value = values[idx];

      return {...t, value, label: value};
    });

    dispatch({type: 'tags:update', payload: updated});
  }

  function handleUpdateTags() {
    dispatch({type: 'updating:start'});

    const {current = [], updated = []} = state;
    const currentIds = current.map((t: any) => t.id);
    const remainingIds = updated
      .filter((t: any) => !!t.id)
      .map((t: any) => t.id);
    const newTagsToCreate = updated
      .filter((t: any) => !t.id)
      .map((t: any) => t.value);
    const tagIdsToAdd = remainingIds.filter(
      (tagId: string) => tagId && currentIds.indexOf(tagId) === -1
    );
    const tagIdsToRemove = currentIds.filter(
      (tagId: string) => remainingIds.indexOf(tagId) === -1
    );

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
      .then(() => dispatch({type: 'updating:done'}));
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
            value={state.updated.map((t: any) => t.value)}
            onChange={handleChangeTags}
            options={state.options.map((tag: any) => {
              const {id, name} = tag;

              return {id, key: id, label: name, value: name};
            })}
          />
        ) : (
          <Flex sx={{flexWrap: 'wrap'}}>
            {state.current && state.current.length ? (
              state.current.map((tag: any, idx: number) => {
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

export default SidebarCustomerTags;
