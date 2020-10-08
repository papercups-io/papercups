import React from 'react';
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import {Box, Flex} from 'theme-ui';
import {colors, Button, Select, Tag, Text, Tooltip} from '../common';
import {
  CalendarOutlined,
  GlobalOutlined,
  MailOutlined,
  PhoneOutlined,
  UserOutlined,
} from '../icons';
import Spinner from '../Spinner';
import * as API from '../../api';
import logger from '../../logger';

// TODO: create date utility methods so we don't have to do this everywhere
dayjs.extend(utc);

const DetailsSectionCard = ({children}: {children: any}) => {
  return (
    <Box
      my={2}
      p={2}
      sx={{
        bg: colors.white,
        border: '1px solid rgba(0,0,0,.06)',
        borderRadius: 4,
      }}
    >
      {children}
    </Box>
  );
};

const CustomerTags = ({customerId}: {customerId: string}) => {
  const [isLoading, setLoading] = React.useState(false);
  const [isEditing, setEditing] = React.useState(false);
  const [isUpdating, setUpdating] = React.useState(false);
  const [customerTags, setCustomerTags] = React.useState([]);
  const [updatedTags, setUpdatedTags] = React.useState([]);
  const [tagOptions, setTagOptions] = React.useState([]);

  // eslint-disable-next-line
  React.useEffect(() => {
    setLoading(true);

    refreshCustomerTags().then(() => setLoading(false));
  }, [customerId]);

  function handleStartEditing() {
    setEditing(true);
  }

  function refreshCustomerTags() {
    return Promise.all([API.fetchCustomer(customerId), API.fetchAllTags()])
      .then(([customer, tags]) => {
        const {tags: customerTags = []} = customer;
        const formattedTags = customerTags.map((tag: any) => {
          return {id: tag.id, label: tag.name, value: tag.name};
        });

        setCustomerTags(customerTags);
        setUpdatedTags(formattedTags);
        setTagOptions(tags);
      })
      .catch((err) => {
        logger.error('Failed to fetch customer details:', err);
      });
  }

  function handleChangeCustomerTags(values: Array<string>, tags: any) {
    const updated = tags.map((t: any, idx: number) => {
      const value = values[idx];

      return {...t, value, label: value};
    });

    setUpdatedTags(updated);
  }

  function handleUpdateCustomerTags() {
    setUpdating(true);

    const initialIds = customerTags.map((t: any) => t.id);
    const remainingIds = updatedTags
      .filter((t: any) => !!t.id)
      .map((t: any) => t.id);
    const newTagsToCreate = updatedTags
      .filter((t: any) => !t.id)
      .map((t: any) => t.value);
    const tagIdsToAdd = remainingIds.filter(
      (tagId) => tagId && initialIds.indexOf(tagId) === -1
    );
    const tagIdsToRemove = initialIds.filter(
      (tagId) => remainingIds.indexOf(tagId) === -1
    );

    const promises = [
      ...newTagsToCreate.map((name) =>
        API.createTag(name).then(({id: tagId}) =>
          API.addCustomerTag(customerId, tagId)
        )
      ),
      ...tagIdsToAdd.map((tagId) => API.addCustomerTag(customerId, tagId)),
      ...tagIdsToRemove.map((tagId) =>
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
      .then(() => refreshCustomerTags())
      .then(() => {
        setEditing(false);
        setUpdating(false);
      });
  }

  if (isLoading) {
    return <Spinner size={16} />;
  }

  return (
    <Box>
      <Box mb={1}>
        {/* TODO: figure out a nicer design for this */}
        {isEditing ? (
          <Select
            mode="tags"
            style={{width: '100%'}}
            placeholder="Add tags"
            value={updatedTags.map((t: any) => t.value)}
            onChange={handleChangeCustomerTags}
            options={tagOptions.map((tag: any) => {
              const {id, name} = tag;

              return {id, key: id, label: name, value: name};
            })}
          />
        ) : (
          <Flex sx={{flexWrap: 'wrap'}}>
            {customerTags && customerTags.length ? (
              customerTags.map((tag: any, idx: number) => {
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
        {isEditing ? (
          <Button
            size="small"
            type="primary"
            loading={isUpdating}
            onClick={handleUpdateCustomerTags}
          >
            Done
          </Button>
        ) : (
          <Button
            size="small"
            loading={isUpdating}
            onClick={handleStartEditing}
          >
            {customerTags && customerTags.length ? 'Edit' : 'Add'}
          </Button>
        )}
      </Box>
    </Box>
  );
};

type Props = {
  customer: any;
  conversation: any;
};

const ConversationDetailsSidebar = ({customer, conversation}: Props) => {
  const {id: conversationId, status} = conversation;
  const {
    email,
    name,
    browser,
    os,
    phone,
    pathname,
    id: customerId,
    external_id: externalId,
    created_at: createdAt,
    updated_at: lastUpdatedAt,
    current_url: lastSeenUrl,
    time_zone: timezone,
    ip: lastIpAddress,
    metadata = {},
  } = customer;
  const hasMetadata = !!metadata && Object.keys(metadata).length > 0;
  const formattedTimezone =
    timezone && timezone.length ? timezone.split('_').join(' ') : null;

  return (
    <Box
      sx={{
        width: '100%',
        minHeight: '100%',
        bg: 'rgb(245, 245, 245)',
        border: `1px solid rgba(0,0,0,.06)`,
        boxShadow: 'inset rgba(0, 0, 0, 0.1) 0px 0px 4px',
        flex: 1,
      }}
    >
      <Box px={2} py={3} sx={{borderBottom: '1px solid rgba(0,0,0,.06)'}}>
        <Box px={2} mb={3}>
          <Text strong>Conversation details</Text>
        </Box>

        <Box
          px={2}
          mb={1}
          sx={{
            maxWidth: '100%',
            overflow: 'hidden',
            whiteSpace: 'nowrap',
            textOverflow: 'ellipsis',
          }}
        >
          <Text type="secondary">ID:</Text>{' '}
          <Tooltip title={conversationId.toLowerCase()} placement="left">
            {conversationId.toLowerCase()}
          </Tooltip>
        </Box>
        <Box px={2} mb={1}>
          <Text type="secondary">Status:</Text>{' '}
          <Tag color={status === 'open' ? colors.primary : colors.red}>
            {status}
          </Tag>
        </Box>

        {false && (
          <DetailsSectionCard>
            <Box mb={2}>
              <Text strong>Tags</Text>
            </Box>
            <Box>Conversation tags</Box>
          </DetailsSectionCard>
        )}
      </Box>

      <Box px={2} py={3}>
        <Box px={2} mb={3}>
          <Text strong>Customer details</Text>
        </Box>

        <DetailsSectionCard>
          <Box mb={2}>
            <Text strong>{name || 'Anonymous User'}</Text>
          </Box>

          <Flex mb={1} sx={{alignItems: 'center'}}>
            <MailOutlined style={{color: colors.primary}} />
            <Box ml={2}>{email || 'Unknown'}</Box>
          </Flex>
          <Flex mb={1} sx={{alignItems: 'center'}}>
            <PhoneOutlined style={{color: colors.primary}} />
            <Box ml={2}>{phone || 'Unknown'}</Box>
          </Flex>
          <Flex mb={1} sx={{alignItems: 'center'}}>
            <UserOutlined style={{color: colors.primary}} />
            <Box
              ml={2}
              sx={{
                maxWidth: '100%',
                overflow: 'hidden',
                whiteSpace: 'nowrap',
                textOverflow: 'ellipsis',
              }}
            >
              <Text type="secondary">ID:</Text>{' '}
              <Tooltip title={externalId || customerId} placement="left">
                {externalId || customerId}
              </Tooltip>
            </Box>
          </Flex>
        </DetailsSectionCard>

        <DetailsSectionCard>
          <Box mb={2}>
            <Text strong>Last seen</Text>
          </Box>
          <Box mb={1}>
            <CalendarOutlined />{' '}
            {lastUpdatedAt
              ? dayjs.utc(lastUpdatedAt).format('MMMM DD, YYYY')
              : 'N/A'}{' '}
            <Text type="secondary">at</Text>
          </Box>
          <Box mb={1}>
            {lastSeenUrl ? (
              <Tooltip title={lastSeenUrl}>
                <a href={lastSeenUrl} target="_blank" rel="noopener noreferrer">
                  {pathname && pathname.length > 1 ? pathname : lastSeenUrl}
                </a>
              </Tooltip>
            ) : (
              <Text>Unknown URL</Text>
            )}
          </Box>
        </DetailsSectionCard>

        <DetailsSectionCard>
          <Box mb={2}>
            <Text strong>First seen</Text>
          </Box>
          <Box>
            <CalendarOutlined />{' '}
            {createdAt ? dayjs.utc(createdAt).format('MMMM DD, YYYY') : 'N/A'}
          </Box>
        </DetailsSectionCard>

        {hasMetadata && (
          <DetailsSectionCard>
            <Box mb={2}>
              <Text strong>Metadata</Text>
            </Box>

            {Object.entries(metadata).map(([key, value]) => {
              return (
                <Box key={key} mb={1}>
                  <Text type="secondary">{key}:</Text> {String(value)}
                </Box>
              );
            })}
          </DetailsSectionCard>
        )}

        <DetailsSectionCard>
          <Box mb={2}>
            <Text strong>Device</Text>
          </Box>
          {formattedTimezone && (
            <Box mb={1}>
              <GlobalOutlined /> {formattedTimezone}
            </Box>
          )}
          <Box mb={1}>
            {[os, browser].filter(Boolean).join(' · ') || 'Unknown'}
          </Box>
          <Box mb={1}>
            <Text type="secondary">IP:</Text> {lastIpAddress || 'Unknown'}
          </Box>
        </DetailsSectionCard>

        <DetailsSectionCard>
          <Box mb={2}>
            <Text strong>Tags</Text>
          </Box>
          <CustomerTags customerId={customerId} />
        </DetailsSectionCard>
      </Box>
    </Box>
  );
};

export default ConversationDetailsSidebar;
