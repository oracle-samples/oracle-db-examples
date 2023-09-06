select score(0), text from avtest where contains (text, '
<query>
  <textquery>
    <progression>
      <seq>(cat dog rabbit fox) not fish</seq>
      <seq>(cat near dog near rabbit near fox) not fish</seq>
      <seq>(cat near dog and rabbit and fox) not fish</seq> 
      <seq>(cat and dog and rabbit) not fish</seq>
      <seq>(cat or dog or rabbit) not fish</seq>
    </progression>
  </textquery>
</query>',0) > 0
order by score(0) desc
/
