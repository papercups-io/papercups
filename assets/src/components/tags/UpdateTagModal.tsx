import React from 'react';
import {Box, Flex} from 'theme-ui';
import {colors, Button, Input, Modal, Select, Text, TextArea} from '../common';
import * as API from '../../api';
import {formatServerError} from '../../utils';
import {Tag} from '../../types';
import logger from '../../logger';
import {TAG_COLORS} from './support';

const UpdateTagModal = ({
  tag,
  visible,
  onSuccess,
  onCancel,
}: {
  tag: Tag;
  visible: boolean;
  onSuccess: (params: any) => void;
  onCancel: () => void;
}) => {
  const {
    id: tagId,
    name: initialName,
    description: initialDescription,
    color: initialColor,
  } = tag;
  const [name, setName] = React.useState(initialName);
  const [description, setDescription] = React.useState(initialDescription);
  const [color, setColor] = React.useState(initialColor);
  const [error, setErrorMessage] = React.useState<string | null>(null);
  const [isSaving, setIsSaving] = React.useState(false);

  const resetInputFields = React.useCallback(() => {
    setName(initialName);
    setDescription(initialDescription);
    setColor(initialColor);
    setErrorMessage(null);
  }, [initialName, initialDescription, initialColor]);

  React.useEffect(() => resetInputFields(), [tag, resetInputFields]);

  const handleChangeName = (e: any) => setName(e.target.value);
  const handleChangeDescription = (e: any) => setDescription(e.target.value);

  const handleCancelTag = () => {
    onCancel();

    setTimeout(() => resetInputFields(), 400);
  };

  const handleCreateTag = async () => {
    setIsSaving(true);

    return API.updateTag(tagId, {name, description, color})
      .then((result) => onSuccess(result))
      .catch((err) => {
        logger.error('Error updating tag:', err);
        const errorMessage = formatServerError(err);
        setErrorMessage(errorMessage);
      })
      .finally(() => setIsSaving(false));
  };

  return (
    <Modal
      title="Edit tag details"
      visible={visible}
      width={400}
      onOk={handleCreateTag}
      onCancel={handleCancelTag}
      footer={[
        <Button key="cancel" onClick={handleCancelTag}>
          Cancel
        </Button>,
        <Button
          key="submit"
          type="primary"
          loading={isSaving}
          onClick={handleCreateTag}
        >
          Save
        </Button>,
      ]}
    >
      <Box>
        <Box mb={3}>
          <label htmlFor="name">Name</label>
          <Input
            id="name"
            type="text"
            value={name}
            onChange={handleChangeName}
          />
        </Box>
        <Box mb={3}>
          <label htmlFor="description">Description</label>
          <TextArea
            id="description"
            value={description}
            onChange={handleChangeDescription}
          />
        </Box>
        <Box mb={3}>
          <label htmlFor="color">Color</label>

          <Select
            id="color"
            style={{width: '100%'}}
            value={color}
            onChange={setColor}
          >
            {TAG_COLORS.map(({name, hex}) => (
              <Select.Option key={name} value={name}>
                <Flex sx={{alignItems: 'center'}}>
                  <Box
                    mr={2}
                    sx={{
                      height: 8,
                      width: 8,
                      bg: hex,
                      borderRadius: '50%',
                      border:
                        name === 'default'
                          ? `1px solid ${colors.gray[0]}`
                          : null,
                    }}
                  ></Box>
                  <Text>{name}</Text>
                </Flex>
              </Select.Option>
            ))}
          </Select>
        </Box>

        {error && (
          <Box mb={-3}>
            <Text type="danger">{error}</Text>
          </Box>
        )}
      </Box>
    </Modal>
  );
};

export default UpdateTagModal;
