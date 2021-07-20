import React from 'react';
import {Flex} from 'theme-ui';
import * as monaco from 'monaco-editor';
import Editor, {EditorProps, BeforeMount, Monaco} from '@monaco-editor/react';

export const MonacoEditor = (props: EditorProps) => {
  const handleEditorChange = (value: string | undefined, event: any) => {
    // TODO
  };

  const handleEditorDidMount = (
    editor: monaco.editor.IStandaloneCodeEditor,
    monaco: Monaco
  ) => {
    // TODO
  };

  const handleEditorWillMount: BeforeMount = (monaco: Monaco) => {
    // TODO
  };

  const handleEditorValidation = (markers: monaco.editor.IMarker[]) => {
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
      {...props}
    />
  );
};

export default MonacoEditor;
