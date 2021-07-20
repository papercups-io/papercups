import React from 'react';
import {Flex} from 'theme-ui';
import Editor, {EditorProps, BeforeMount, Monaco} from '@monaco-editor/react';

type Props = {onSave?: (code: string) => void} & EditorProps;

export const MonacoEditor = (props: Props) => {
  const {onMount, onSave, ...rest} = props;

  const handleEditorDidMount = (editor: any, monaco: Monaco) => {
    if (onMount) {
      onMount(editor, monaco);
    }

    if (onSave) {
      editor.addAction({
        id: 'save',
        label: 'Save',
        keybindings: [2048 | 49], // [KeyMod.CtrlCmd | KeyCode.KEY_S]
        contextMenuGroupId: 'navigation',
        contextMenuOrder: 1.5,
        run: () => {
          const code = editor.getValue() ?? '';

          onSave(code);
        },
      });
    }
  };

  const handleEditorChange = (value: string | undefined, event: any) => {
    // TODO
  };

  const handleEditorWillMount: BeforeMount = (monaco: Monaco) => {
    // TODO
  };

  const handleEditorValidation = (markers: any[]) => {
    // TODO
  };

  return (
    <Editor
      height="100%"
      defaultLanguage="javascript"
      theme="vs-dark"
      defaultValue="// write code below!"
      loading={
        <Flex
          sx={{
            bg: '#1e1e1e',
            flex: 1,
            height: '100%',
            width: '100%',
          }}
        ></Flex>
      }
      onChange={handleEditorChange}
      onMount={handleEditorDidMount}
      beforeMount={handleEditorWillMount}
      onValidate={handleEditorValidation}
      {...rest}
    />
  );
};

export default MonacoEditor;
