import React, {useState} from 'react';
import * as API from '../../api';
import {Box} from 'theme-ui';
import logger from '../../logger';
import {CustomerNote} from '../../types';
import {TextArea, Text, Button} from '../common';
import {formatServerError} from '../../utils';

const CustomerDetailNewNoteInput = ({
  customerId,
  onCreateNote,
}: {
  customerId: string;
  onCreateNote: (note: CustomerNote) => void;
}) => {
  const [isSaving, setIsSaving] = useState(false);
  const [errorMessage, setErrorMessage] = useState('');
  const [note, setNote] = useState('');

  const handleNoteChange = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
    setNote(e.target.value);
  };

  const handleSaveNote = async () => {
    if (isSaving || note.length < 1) {
      return;
    }

    setIsSaving(true);

    try {
      const newNote = await API.createCustomerNote(customerId, note);
      onCreateNote(newNote);
      setNote('');
    } catch (error) {
      logger.error('Error creating customer note:', error);
      const errorMessage = formatServerError(error);
      setErrorMessage(errorMessage);
    }

    setIsSaving(false);
  };

  return (
    <Box mb={2}>
      <TextArea
        style={{background: 'transparent'}}
        placeholder="Add a note"
        autoSize={{minRows: 2}}
        disabled={isSaving}
        value={note}
        onChange={handleNoteChange}
      />
      {errorMessage && (
        <Box mt={3}>
          <Text type="danger" strong>
            {errorMessage}
          </Text>
        </Box>
      )}
      <Box mt={3}>
        <Button onClick={handleSaveNote} disabled={isSaving || note.length < 1}>
          Add Note
        </Button>
      </Box>
    </Box>
  );
};

export default CustomerDetailNewNoteInput;
