using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using System.Linq;
using System.IO;

public class Manager : MonoBehaviour
{
    [System.Serializable]
    struct Question
    {
        public Question(string txt, string answr)
        {
            text = txt;
            answer = answr;
        }

        public string text;
        public string answer;

    }

    private LinkedList<Question> bank = new LinkedList<Question>();
    private LinkedList<Question> questions = new LinkedList<Question>();

    private Question cur_q;

    public Text card_txt;

    public GameObject card;

    public GameObject prompt;

    public GameObject flipped;
    public Button restart;

    public InputField fileinput;
    string filename = "";

    private bool isFlipped = false;


    private int left;
    private int total;
    private int correct;
    private int incorrect;

    public Text wrong;
    public Text remaining;
    public Text right;

    private bool finished = false;

    private bool ready = false;

    public Animator anime;

    private int flipping = 0;


    // Start is called before the first frame update
    void Start()
    {
        setUp();
    }


    private bool getQBank()
    {
        Debug.Log(filename);

        bank.Clear();

        StreamReader reader;

        try
        {
            reader = new StreamReader(filename);
        }
        catch (IOException e)
        {
            filename += "\n ERROR: " + e.Message;

            return false;
        }

        LinkedList<string> data = new LinkedList<string>();

        bool r_q = false;
        bool r_a = false;

        while(!reader.EndOfStream)
        {
            data.AddLast(reader.ReadLine());
        }
        reader.Close();

        Debug.Log(data);


        string q = "";
        string a = "";

        foreach (string l in data)
        {
            if(l == "%%")
            {
                if (!r_q && !r_a)
                    r_q = true;
                else if (r_q && !r_a)
                {
                    r_a = true;
                    r_q = false;
                }
                else if (r_a && !r_q)
                {
                    bank.AddLast(new Question(q, a));
                    q = "";
                    a = "";

                    r_a = false;
                    r_q = true;
                }
            }
            else
            {
                if(r_q)
                {
                    q += l + "\n";
                }
                else if (r_a)
                {
                    a += l + "\n";
                }
            }
        }

        return true;
    }


    private LinkedList<Question> shuffle(LinkedList<Question> qs)
    {
        LinkedList<Question> newQ = new LinkedList<Question>();
        
        while (qs.Count > 0)
        {
            var q = qs.ElementAt(Random.Range(0, qs.Count));
            qs.Remove(q);

            newQ.AddLast(q);
        }

        return newQ;
    }

    private void getfile()
    {
        string p = System.IO.Directory.GetCurrentDirectory();
        if (filename != "")
            filename = p + "\\" + fileinput.text;
        else
            filename = p + "\\def_qbank.txt";
    }

    private void setUp()
    {
        getfile();

        ready = false;
        finished = false;
        correct = 0;
        incorrect = 0;

        if (!getQBank())
        {
            card_txt.text = "FILE COULD NOT BE OPENED.\n\nThe offending file: " + filename;
            return;
        }

        if (bank.Count() == 0)
        {
            card_txt.text = "THE QUESTION BANK CONTAINS NO QUESTIONS";
            return;
        }

        questions = new LinkedList<Question>(bank);
        questions = shuffle(questions);
        total = questions.Count;

        cur_q = questions.First.Value;
        card_txt.text = cur_q.text;

        StartCoroutine(doWait());
    }

    // Update is called once per frame
    void Update()
    {
        getfile();

        if (ready)
        {

            if (flipped.activeSelf != isFlipped)
                flipped.SetActive(isFlipped);

            card.SetActive(!isFlipped);

            prompt.SetActive(!isFlipped);

            if (!finished)
            {
                if (isFlipped)
                {
                    card_txt.text = cur_q.answer;
                }
                else
                    card_txt.text = cur_q.text;
            }
            else
                card_txt.text = "Quiz Complete!\n\nClick Restart to run the Quiz again.";
        }

        left = questions.Count;


        remaining.text = left + " of " + total;
        wrong.text = " " + incorrect;
        right.text = " " + correct;

    }

    public IEnumerator doWait()
    {
        yield return new WaitForSeconds(0.5f);
        ready = true;
        yield return null;
    }

    public void flip()
    {
        if (!ready && flipping != 2)
            return;

        if (flipping == 0)
            isFlipped = true;
        else if (flipping == 2)
            performRestart();
        else
        {
            isFlipped = false;
            next();
        }

        flipping = 0;
    }

    public void performFlip()
    {

        if (!ready && flipping != 2)
            return;

        anime.SetTrigger("flip");
    }

    public void Flip()
    {
        if (isFlipped || finished)
            return;

        flipping = 0;
        performFlip();
    }

    public void next()
    {
        questions.RemoveFirst();

        if (questions.Count > 0)
            cur_q = questions.First.Value;
        else
            finish();
    }

    public void finish()
    {
        finished = true;
    }

    private void doNext()
    {
        flipping = 1;
        performFlip();
    }

    public void confirm()
    {
        correct += 1;
        doNext();
    }

    public void nope()
    {
        incorrect += 1;
        doNext();
    }

    private void performRestart()
    {
        setUp();
        isFlipped = false;
    }

    public void doRestart()
    {

        flipping = 2;
        performFlip();

    }
}
