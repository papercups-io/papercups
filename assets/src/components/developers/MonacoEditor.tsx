import React from 'react';
import Editor, {EditorProps} from '@monaco-editor/react';

export const MonacoEditor = (props: EditorProps) => {
  function handleEditorChange(value: any, event: any) {
    // here is the current value
    console.log('onChange:', value);
  }

  function handleEditorDidMount(editor: any, monaco: any) {
    console.log('onMount: the editor instance:', editor);
    console.log('onMount: the monaco instance:', monaco);

    // debugger;
  }

  function handleEditorWillMount(monaco: any) {
    console.log('beforeMount: the monaco instance:', monaco);
  }

  function handleEditorValidation(markers: any) {
    // model markers
    markers.forEach((marker: any) =>
      console.log('onValidate:', marker.message)
    );
  }

  return (
    <Editor
      height="100%"
      defaultLanguage="javascript"
      defaultValue="// some comment"
      onChange={handleEditorChange}
      onMount={handleEditorDidMount}
      beforeMount={handleEditorWillMount}
      onValidate={handleEditorValidation}
      {...props}
    />
  );
};
